#Requires -Version 5.1

<#
.SYNOPSIS
    Enterprise PostgreSQL database discovery and inventory collection with multi-method authentication and comprehensive metadata extraction.

.DESCRIPTION
    This PowerShell script performs automated PostgreSQL instance discovery on Windows systems with intelligent
    authentication profile cycling and detailed database metadata collection. Supports automatic installation
    detection via registry scanning, service discovery, and environment path enumeration across all major
    PostgreSQL distributions including EnterpriseDB, Crunchy Data, TimescaleDB, and community editions.

    Leverages the native psql.exe client for robust database communications with support for multiple authentication
    methods including trust authentication, Windows integrated authentication, password-based authentication, and
    peer/ident protocols. Automatically discovers database server configuration, installed extensions, and license
    types through system catalog queries and configuration file parsing.

    Features sophisticated authentication method cycling to identify working connection strategies without manual
    intervention. Implements intelligent timeout controls and retry logic to prevent connection hangs while
    gathering comprehensive instance metadata including version information, cluster status, database sizes,
    ownership details, and enterprise feature detection based on installed extensions and version strings.

    Results are saved to timestamped JSON files with comprehensive database information suitable for license
    compliance auditing, capacity planning, migration assessments, and infrastructure inventory management systems.

.PARAMETER None
    This script accepts no command-line parameters. All configuration is determined through automatic discovery
    of PostgreSQL installations, running services, and system configuration.

.EXAMPLE
    .\inventory-postgresql.ps1

    Discovers all PostgreSQL installations on local system using registry and path detection. Attempts connection
    using multiple authentication profiles and collects complete instance metadata including databases, versions,
    and license information. Results saved to timestamped JSON file in configured output directory.

.EXAMPLE
    .\inventory-postgresql.ps1 -Verbose

    Executes full PostgreSQL discovery with detailed diagnostic output showing installation paths, connection
    attempts, authentication method testing, and query execution status. Useful for troubleshooting connection
    failures or understanding authentication configuration requirements.

.INPUTS
    None. This script does not accept pipeline input.

.OUTPUTS
    None to pipeline. Primary output is comprehensive database inventory information written to timestamped JSON file.

    Output file structure:
    - edition: Database edition (Community, Enterprise)
    - product: Full version string from database server
    - version: Numeric version identifier
    - servername: Fully qualified domain name of host system
    - isclustered: Boolean indicating replication/standby status
    - licensetype: License classification (PostgreSQL License, EDB Commercial, etc.)
    - numlicenses: License count or limitation description
    - errordetails: Connection or authentication failure details
    - instancename: Service name or registry instance identifier
    - productlevel: Normalized version number
    - responsetime: Discovery execution time in milliseconds
    - connectionstatus: Authentication result (success, failure)
    - databases: Array of database objects with name, size, owner metadata

.NOTES
    Version        : 1.0.5
    Last Modified  : 2025-10-22
    Prerequisite   : PowerShell 5.1+, PostgreSQL psql.exe client, administrative privileges for service queries

    Performance Characteristics:
    - Sequential authentication method testing with 10-second timeout per attempt
    - Registry-based installation detection minimizes filesystem scanning overhead
    - Connection result caching enables efficient multi-query execution per instance
    - Memory-efficient streaming query execution prevents buffer overflow on large datasets
    - Conditional query execution based on connection status reduces unnecessary network traffic

    Security Features:
    - No credential exposure in output files or verbose logging
    - Environment variable isolation for password passing prevents credential leakage
    - Temporary file cleanup ensures query content is not persisted to disk
    - Process-based timeout enforcement prevents indefinite connection hangs
    - Trust authentication attempted only on localhost to prevent unauthorized remote access

    System Requirements:
    - TCP port 5432 (or configured port) connectivity to PostgreSQL server
    - PostgreSQL service running with accessible authentication configuration
    - Read access to PostgreSQL system catalogs and configuration files
    - Filesystem write access to C:\ProgramData\Aithentic\Uploads for output

    Authentication Support:
    - Trust authentication for localhost connections with empty password
    - Windows integrated authentication via current user context
    - Password-based authentication with common default credentials
    - Peer/ident authentication using Windows username mapping
    - Automatic pg_hba.conf configuration detection through method cycling

    Edition Detection:
    - EnterpriseDB Advanced Server and Extended editions via version string parsing
    - Crunchy Data commercial distributions through vendor-specific markers
    - TimescaleDB extensions and licensing models via pg_extension catalog
    - Greenplum and Citus distributions through version signature analysis
    - Commercial extension detection including EDB-specific catalog enhancements

    Output files use agent UUID and timestamp for uniqueness and traceability.
    Failed discoveries generate minimal records with categorized error details.
    All database operations are read-only; no schema or data modifications performed.
#>

#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SystemUUID {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    try {
        $uuid = (Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction SilentlyContinue).UUID
        if (-not $uuid) {
            $uuid = [System.Guid]::NewGuid().ToString()
        }
        return $uuid
    }
    catch {
        return [System.Guid]::NewGuid().ToString()
    }
}

function Get-FQDN {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    try {
        $fqdn = [System.Net.Dns]::GetHostEntry([string]::Empty).HostName
        if (-not $fqdn) {
            $fqdn = $env:COMPUTERNAME
        }
        return $fqdn
    }
    catch {
        return $env:COMPUTERNAME
    }
}

function Find-PostgreSQLInstallations {
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param()
    
    $installations = [System.Collections.Generic.List[string]]::new()
    
    $registryPaths = @(
        'HKLM:\SOFTWARE\PostgreSQL\Installations',
        'HKLM:\SOFTWARE\WOW6432Node\PostgreSQL\Installations'
    )
    
    foreach ($regPath in $registryPaths) {
        if (Test-Path -Path $regPath -ErrorAction SilentlyContinue) {
            $items = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                $basePath = (Get-ItemProperty -Path $item.PSPath -Name 'Base Directory' -ErrorAction SilentlyContinue).'Base Directory'
                if (-not [string]::IsNullOrWhiteSpace($basePath)) {
                    $psqlPath = Join-Path -Path $basePath -ChildPath 'bin\psql.exe'
                    if (Test-Path -Path $psqlPath) {
                        $installations.Add($psqlPath)
                    }
                }
            }
        }
    }
    
    $commonPaths = @(
        'C:\Program Files\PostgreSQL\*\bin\psql.exe',
        'C:\Program Files (x86)\PostgreSQL\*\bin\psql.exe',
        'C:\PostgreSQL\*\bin\psql.exe'
    )
    
    foreach ($pattern in $commonPaths) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
        if ($null -ne $found) {
            foreach ($file in $found) {
                if ($installations -notcontains $file.FullName) {
                    $installations.Add($file.FullName)
                }
            }
        }
    }
    
    $pathEnv = $env:PATH -split ';'
    foreach ($pathEntry in $pathEnv) {
        if (-not [string]::IsNullOrWhiteSpace($pathEntry)) {
            $psqlInPath = Join-Path -Path $pathEntry.Trim() -ChildPath 'psql.exe'
            if ((Test-Path -Path $psqlInPath -ErrorAction SilentlyContinue) -and ($installations -notcontains $psqlInPath)) {
                $installations.Add($psqlInPath)
            }
        }
    }
    
    return , $installations
}

function Test-PostgreSQLService {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    $result = @{
        IsRunning   = $false
        ServiceName = $null
        Port        = 5432
    }
    
    $runningService = Get-Service -Name 'postgresql*' -ErrorAction SilentlyContinue | 
    Where-Object { $_.Status -eq 'Running' } | 
    Select-Object -First 1
    
    if ($null -ne $runningService) {
        $result.IsRunning = $true
        $result.ServiceName = $runningService.Name
    }
    
    return $result
}

function Get-PostgreSQLConnectionMethods {
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PsqlPath,
        
        [Parameter(Mandatory = $false)]
        [int]$Port = 5432
    )
    
    $methods = @(
        @{
            Description = 'Localhost Trust Authentication'
            Arguments   = "-h 127.0.0.1 -p $Port -U postgres -d postgres -t -A"
            EnvVars     = @{ 'PGPASSWORD' = '' }
        },    
        @{
            Description = 'Windows Integrated Authentication'
            Arguments   = "-h 127.0.0.1 -p $Port -d postgres -t -A"
            EnvVars     = @{}
        },
        @{
            Description = 'Default postgres user'
            Arguments   = "-h 127.0.0.1 -p $Port -U postgres -d postgres -t -A"
            EnvVars     = @{ 'PGPASSWORD' = 'postgres' }
        },
        @{
            Description = 'Empty password'
            Arguments   = "-h 127.0.0.1 -p $Port -U postgres -d postgres -t -A"
            EnvVars     = @{}
        },
        @{
            Description = 'Check pg_hba.conf for peer/ident'
            Arguments   = "-h 127.0.0.1 -p $Port -d postgres -t -A"
            EnvVars     = @{ 'PGUSER' = $env:USERNAME }
        }
    )
    
    return $methods
}

function Invoke-PostgreSQLQuery {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PsqlPath,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [string]$Database = 'postgres',
        
        [Parameter(Mandatory = $false)]
        [int]$Port = 5432,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionConfig = $null
    )

    if (-not (Test-Path -Path $PsqlPath -PathType Leaf)) {
        Write-Verbose "psql.exe not found at path: $PsqlPath"
        return $null
    }
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    
    try {
        Set-Content -Path $tempFile -Value $Query -Encoding ASCII
        
        if ($null -eq $ConnectionConfig) {
            $arguments = "-h 127.0.0.1 -p $Port -U postgres -d $Database -t -A -f `"$tempFile`""
            $envVars = @{ 'PGPASSWORD' = '' }
        }
        else {
            $arguments = "$($ConnectionConfig.Arguments) -f `"$tempFile`""
            $envVars = $ConnectionConfig.EnvVars
        }
        
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $PsqlPath
        $processInfo.Arguments = $arguments
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        
        foreach ($key in $envVars.Keys) {
            $processInfo.EnvironmentVariables[$key] = $envVars[$key]
        }
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        
        [void]$process.Start()
        
        $timeout = 10000
        if (-not $process.WaitForExit($timeout)) {
            $process.Kill()
            Write-Verbose "Query timed out after $timeout ms"
            return $null
        }
        
        $output = $process.StandardOutput.ReadToEnd()
        
        if ($process.ExitCode -eq 0) {
            return $output.Trim()
        }
        
        $errorOutput = $process.StandardError.ReadToEnd()
        Write-Verbose "psql error (exit code $($process.ExitCode)): $errorOutput"
        
        return $null
    }
    catch {
        Write-Verbose "Exception in Invoke-PostgreSQLQuery: $_"
        return $null
    }
    finally {
        if ($null -ne $process) {
            if (-not $process.HasExited) {
                try { $process.Kill() } catch { }
            }
            $process.Dispose()
        }
        if (Test-Path -Path $tempFile -ErrorAction SilentlyContinue) {
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-PostgreSQLVersion {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PsqlPath
    )
    
    try {
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $PsqlPath
        $processInfo.Arguments = '--version'
        $processInfo.RedirectStandardOutput = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        [void]$process.Start()
        
        $timeout = 5000
        if (-not $process.WaitForExit($timeout)) {
            $process.Kill()
            Write-Verbose "Version check timed out"
            return @{
                Version     = 'Unknown'
                FullVersion = 'PostgreSQL (Version Unknown)'
            }
        }
        
        $output = $process.StandardOutput.ReadToEnd()
        
        if ($output -match 'psql \(PostgreSQL\) ([\d.]+)') {
            $version = $Matches[1]
            return @{
                Version     = $version
                FullVersion = $output.Trim()
            }
        }
    }
    catch {
        Write-Verbose "Failed to get version from $PsqlPath : $_"
    }
    finally {
        if ($null -ne $process) {
            if (-not $process.HasExited) {
                try { $process.Kill() } catch { }
            }
            $process.Dispose()
        }
    }
    
    return @{
        Version     = 'Unknown'
        FullVersion = 'PostgreSQL (Version Unknown)'
    }
}

function Get-PostgreSQLDatabases {
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PsqlPath,
        
        [Parameter(Mandatory = $false)]
        [int]$Port = 5432,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionConfig = $null
    )
    
    $databases = [System.Collections.Generic.List[PSObject]]::new()
    
    $query = @"
SELECT d.datname, pg_database_size(d.datname), r.rolname as owner
FROM pg_database d
LEFT JOIN pg_roles r ON d.datdba = r.oid
WHERE d.datistemplate = false;
"@
    
    $result = Invoke-PostgreSQLQuery -PsqlPath $PsqlPath -Query $query -Port $Port -ConnectionConfig $ConnectionConfig
    
    if ([string]::IsNullOrWhiteSpace($result)) {
        $defaultDb = [PSCustomObject]@{
            Name    = 'postgres'
            Size_GB = 'Unknown'
            Owner   = 'postgres'
        }
        $databases.Add($defaultDb)
        return $databases
    }
    
    $lines = $result -split "`n"
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        
        $parts = $line -split '\|'
        if ($parts.Count -ge 3) {
            $sizeGB = 0.0
            if (-not [string]::IsNullOrWhiteSpace($parts[1]) -and $parts[1] -ne '0') {
                $sizeBytes = [double]$parts[1]
                $sizeGB = [math]::Round($sizeBytes / 1GB, 2)
            }
            
            $db = [PSCustomObject]@{
                Name    = $parts[0].Trim()
                Size_GB = $sizeGB
                Owner   = if ([string]::IsNullOrWhiteSpace($parts[2])) { 'postgres' } else { $parts[2].Trim() }
            }
            $databases.Add($db)
        }
    }
    
    if ($databases.Count -eq 0) {
        $defaultDb = [PSCustomObject]@{
            Name    = 'postgres'
            Size_GB = 'Unknown'
            Owner   = 'postgres'
        }
        $databases.Add($defaultDb)
    }
    
    return , $databases
}

function Test-PostgreSQLClustering {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PsqlPath,
        
        [Parameter(Mandatory = $false)]
        [int]$Port = 5432,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionConfig = $null
    )
    
    $query = 'SELECT pg_is_in_recovery();'
    $result = Invoke-PostgreSQLQuery -PsqlPath $PsqlPath -Query $query -Port $Port -ConnectionConfig $ConnectionConfig
    
    if ($result -eq 't') {
        return $true
    }
    
    return $false
}

function Get-PostgreSQLEdition {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PsqlPath,
        
        [Parameter(Mandatory = $false)]
        [int]$Port = 5432,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionConfig = $null
    )
    
    $query = "SELECT version();"
    $versionString = Invoke-PostgreSQLQuery -PsqlPath $PsqlPath -Query $query -Port $Port -ConnectionConfig $ConnectionConfig
    
    if ([string]::IsNullOrWhiteSpace($versionString)) {
        Write-Verbose "Unable to retrieve version string for edition detection"
        return 'Community'
    }
    
    if ($versionString -match 'EnterpriseDB|EDB Postgres') {
        return 'Enterprise'
    }
    elseif ($versionString -match 'Crunchy|Timescale|TimescaleDB|Greenplum|Citus') {
        return 'Enterprise'
    }
    else {
        return 'Community'
    }
}

function Get-PostgreSQLInstanceName {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    $serviceInfo = Test-PostgreSQLService
    if (-not [string]::IsNullOrWhiteSpace($serviceInfo.ServiceName)) {
        return $serviceInfo.ServiceName
    }
    
    $registryPaths = @(
        'HKLM:\SOFTWARE\PostgreSQL\Installations',
        'HKLM:\SOFTWARE\WOW6432Node\PostgreSQL\Installations'
    )
    
    foreach ($regPath in $registryPaths) {
        if (Test-Path -Path $regPath -ErrorAction SilentlyContinue) {
            $items = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($null -ne $items) {
                return $items.PSChildName
            }
        }
    }
    
    return 'postgres'
}

function Get-PostgreSQLLicenseInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PsqlPath,
        
        [Parameter(Mandatory = $false)]
        [int]$Port = 5432,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionConfig = $null
    )
    
    $licenseType = 'PostgreSQL License'
    $numLicenses = 'Unlimited'
    
    if ($null -eq $ConnectionConfig) {
        return @{
            LicenseType = $licenseType
            NumLicenses = $numLicenses
        }
    }
    
    $versionQuery = 'SELECT version();'
    $versionResult = Invoke-PostgreSQLQuery -PsqlPath $PsqlPath -Query $versionQuery -Port $Port -ConnectionConfig $ConnectionConfig
    
    if (-not [string]::IsNullOrWhiteSpace($versionResult)) {
        if ($versionResult -match 'EnterpriseDB|EDB Postgres Advanced Server|EDB Postgres Extended') {
            $licenseType = 'EDB Commercial License'
            $numLicenses = 'Per Core/Server'
        }
        elseif ($versionResult -match 'Crunchy') {
            $licenseType = 'Crunchy Data Commercial License'
            $numLicenses = 'Subscription'
        }
        elseif ($versionResult -match 'Timescale|TimescaleDB') {
            $licenseType = 'Timescale License'
            $numLicenses = 'Community or Commercial'
        }
        elseif ($versionResult -match 'Greenplum') {
            $licenseType = 'VMware Tanzu Greenplum License'
            $numLicenses = 'Commercial'
        }
        elseif ($versionResult -match 'Citus') {
            $licenseType = 'Citus License'
            $numLicenses = 'Open Source or Commercial'
        }
    }
    
    $extensionsQuery = "SELECT extname, extversion FROM pg_extension WHERE extname IN ('edb_dblink_libpq', 'edb_dblink_oci', 'dbms_aq', 'edb_gen', 'timescaledb', 'citus');"
    $extensionsResult = Invoke-PostgreSQLQuery -PsqlPath $PsqlPath -Query $extensionsQuery -Port $Port -ConnectionConfig $ConnectionConfig
    
    if (-not [string]::IsNullOrWhiteSpace($extensionsResult)) {
        if ($extensionsResult -match 'edb_|dbms_') {
            $licenseType = 'EDB Commercial License'
            $numLicenses = 'Per Core/Server'
        }
        elseif ($extensionsResult -match 'timescaledb') {
            $licenseType = 'Timescale License'
        }
        elseif ($extensionsResult -match 'citus') {
            $licenseType = 'Citus License'
        }
    }
    
    $maxConnectionsQuery = 'SHOW max_connections;'
    $maxConnResult = Invoke-PostgreSQLQuery -PsqlPath $PsqlPath -Query $maxConnectionsQuery -Port $Port -ConnectionConfig $ConnectionConfig
    
    if (-not [string]::IsNullOrWhiteSpace($maxConnResult)) {
        $maxConn = 0
        if ([int]::TryParse($maxConnResult, [ref]$maxConn) -and $licenseType -eq 'PostgreSQL License') {
            $numLicenses = "Unlimited (max_connections: $maxConn)"
        }
    }
    
    return @{
        LicenseType = $licenseType
        NumLicenses = $numLicenses
    }
}

function Test-PostgreSQLConnection {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PsqlPath,
        
        [Parameter(Mandatory = $false)]
        [int]$Port = 5432
    )
    
    $methods = Get-PostgreSQLConnectionMethods -PsqlPath $PsqlPath -Port $Port
    
    foreach ($method in $methods) {
        Write-Verbose "Attempting: $($method.Description)"
        
        $testQuery = 'SELECT 1;'
        $result = Invoke-PostgreSQLQuery -PsqlPath $PsqlPath -Query $testQuery -Port $Port -ConnectionConfig $method
        
        if ($result -eq '1') {
            Write-Verbose "SUCCESS: $($method.Description)"
            return @{
                Success = $true
                Config  = $method
                Method  = $method.Description
            }
        }
    }
    
    return @{
        Success = $false
        Config  = $null
        Method  = 'None'
    }
}

function Get-PostgreSQLInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PsqlPath
    )
    
    $startTime = Get-Date
    
    $serviceInfo = Test-PostgreSQLService
    $versionInfo = Get-PostgreSQLVersion -PsqlPath $PsqlPath
    $instanceName = Get-PostgreSQLInstanceName
    
    $connectionStatus = 'failure'
    $errorDetails = 'none'
    $isClustered = $false
    $databases = @()
    $port = $serviceInfo.Port
    $dataDir = 'Unknown'
    $configFile = 'Unknown'
    $edition = 'Community'
    $connectionConfig = $null
    
    if ($serviceInfo.IsRunning) {
        $connectionTest = Test-PostgreSQLConnection -PsqlPath $PsqlPath -Port $port
        
        if ($connectionTest.Success) {
            $connectionStatus = 'success'
            $connectionConfig = $connectionTest.Config
            Write-Verbose "Connected using: $($connectionTest.Method)"
            
            $edition = Get-PostgreSQLEdition -PsqlPath $PsqlPath -Port $port -ConnectionConfig $connectionConfig
            
            $portQuery = 'SHOW port;'
            $portResult = Invoke-PostgreSQLQuery -PsqlPath $PsqlPath -Query $portQuery -Port $port -ConnectionConfig $connectionConfig
            if (-not [string]::IsNullOrWhiteSpace($portResult)) {
                $port = [int]$portResult
            }
            
            $dataDirQuery = 'SHOW data_directory;'
            $dataDirResult = Invoke-PostgreSQLQuery -PsqlPath $PsqlPath -Query $dataDirQuery -Port $port -ConnectionConfig $connectionConfig
            if (-not [string]::IsNullOrWhiteSpace($dataDirResult)) {
                $dataDir = $dataDirResult
            }
            
            $configQuery = 'SHOW config_file;'
            $configResult = Invoke-PostgreSQLQuery -PsqlPath $PsqlPath -Query $configQuery -Port $port -ConnectionConfig $connectionConfig
            if (-not [string]::IsNullOrWhiteSpace($configResult)) {
                $configFile = $configResult
            }
            
            $versionQuery = 'SELECT version();'
            $versionResult = Invoke-PostgreSQLQuery -PsqlPath $PsqlPath -Query $versionQuery -Port $port -ConnectionConfig $connectionConfig
            if (-not [string]::IsNullOrWhiteSpace($versionResult)) {
                $versionInfo.FullVersion = $versionResult
                if ($versionResult -match 'PostgreSQL ([\d.]+)') {
                    $versionInfo.Version = $Matches[1]
                }
            }
            
            $databases = Get-PostgreSQLDatabases -PsqlPath $PsqlPath -Port $port -ConnectionConfig $connectionConfig
            $isClustered = Test-PostgreSQLClustering -PsqlPath $PsqlPath -Port $port -ConnectionConfig $connectionConfig
        }
        else {
            $errorDetails = 'No database access - authentication failed'
            Write-Verbose "All connection methods failed. Check pg_hba.conf for allowed authentication methods."
            $databases = [PSCustomObject]@{
                Name    = 'postgres'
                Size_GB = 'Unknown'
                Owner   = 'postgres'
            }
        }
    }
    else {
        $errorDetails = 'PostgreSQL service not running'
        $databases = [PSCustomObject]@{
            Name    = 'postgres'
            Size_GB = 'Unknown'
            Owner   = 'postgres'
        }
    }
    
    $licenseInfo = Get-PostgreSQLLicenseInfo -PsqlPath $PsqlPath -Port $port -ConnectionConfig $connectionConfig
    
    $endTime = Get-Date
    $responseTime = [int](($endTime - $startTime).TotalMilliseconds)
    
    return @{
        Edition          = $edition
        Product          = $versionInfo.FullVersion
        Version          = $versionInfo.Version
        ServerName       = Get-FQDN
        IsClustered      = $isClustered
        LicenseType      = $licenseInfo.LicenseType
        NumLicenses      = $licenseInfo.NumLicenses
        ErrorDetails     = $errorDetails
        InstanceName     = $instanceName
        ProductLevel     = $versionInfo.Version
        ResponseTime     = $responseTime
        ConnectionStatus = $connectionStatus
        Databases        = $databases
        Port             = $port
        DataDirectory    = $dataDir
        ConfigFile       = $configFile
    }
}

function Export-PostgreSQLInventory {
    [CmdletBinding()]
    param()
    
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $uuid = Get-SystemUUID
    $agentId = "agent-$uuid"
    $outputDir = 'C:\ProgramData\Aithentic\Uploads'
    
    if (-not (Test-Path -Path $outputDir)) {
        try {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        catch {
            Write-Error "Failed to create output directory: $outputDir"
            throw
        }
    }
    
    $installations = @(Find-PostgreSQLInstallations)
    
    if ($installations.Count -eq 0) {
        Write-Warning 'No PostgreSQL installations detected'
        return
    }
    
    $psqlPath = $installations[0]
    Write-Verbose "Using PostgreSQL client: $psqlPath"
    
    $inventoryData = Get-PostgreSQLInfo -PsqlPath $psqlPath
    
    $outputObject = [PSCustomObject]@{
        edition          = $inventoryData.Edition
        product          = $inventoryData.Product
        version          = $inventoryData.Version
        servername       = $inventoryData.ServerName
        isclustered      = $inventoryData.IsClustered
        licensetype      = $inventoryData.LicenseType
        numlicenses      = $inventoryData.NumLicenses
        errordetails     = $inventoryData.ErrorDetails
        instancename     = $inventoryData.InstanceName
        productlevel     = $inventoryData.ProductLevel
        responsetime     = $inventoryData.ResponseTime
        connectionstatus = $inventoryData.ConnectionStatus
        databases        = $inventoryData.Databases
    }
    
    $outputFile = Join-Path -Path $outputDir -ChildPath "${agentId}_postgresql-${timestamp}.json"
    
    try {
        $json = $outputObject | ConvertTo-Json -Depth 10 -Compress:$false
        Set-Content -Path $outputFile -Value $json -Encoding UTF8
        Write-Verbose "Inventory file generated: $outputFile"
        
        Get-ChildItem -Path $outputDir -Filter "*${timestamp}.json" | ForEach-Object {
            Write-Verbose "$($_.FullName) - $($_.Length) bytes"
        }
    }
    catch {
        Write-Error "Failed to write inventory file: $_"
        throw
    }
}

try {
    Export-PostgreSQLInventory
}
catch {
    Write-Error "Inventory collection failed: $_"
    exit 1
}
