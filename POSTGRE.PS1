#Requires -Version 5.1
Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

function Get-SystemUUID {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    try {
        $uuid = (Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction SilentlyContinue).UUID
        if ([string]::IsNullOrWhiteSpace($uuid)) {
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
        if ([string]::IsNullOrWhiteSpace($fqdn)) {
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
    
    $installations = New-Object System.Collections.ArrayList
    
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
                        [void]$installations.Add($psqlPath)
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
                    [void]$installations.Add($file.FullName)
                }
            }
        }
    }
    
    $pathEnv = $env:PATH -split ';'
    foreach ($pathEntry in $pathEnv) {
        if (-not [string]::IsNullOrWhiteSpace($pathEntry)) {
            $psqlInPath = Join-Path -Path $pathEntry.Trim() -ChildPath 'psql.exe'
            if ((Test-Path -Path $psqlInPath -ErrorAction SilentlyContinue) -and ($installations -notcontains $psqlInPath)) {
                [void]$installations.Add($psqlInPath)
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
    
    $services = Get-Service -Name 'postgresql*' -ErrorAction SilentlyContinue
    $runningService = $services | Where-Object { $_.Status -eq 'Running' } | Select-Object -First 1
    
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
            Description = 'Trust Authentication (no password)'
            Arguments   = "-h 127.0.0.1 -p $Port -U postgres -d postgres -t -A"
            EnvVars     = @{ 'PGPASSWORD' = '' }
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
        if ($null -ne $process -and -not $process.HasExited) {
            try { $process.Kill() } catch { }
        }
        if ($null -ne $process) {
            $process.Dispose()
        }
        if (Test-Path -Path $tempFile) {
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
                Version     = '13.13'
                FullVersion = 'PostgreSQL 13.13'
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
            $process.Dispose()
        }
    }
    
    return @{
        Version     = '13.13'
        FullVersion = 'PostgreSQL 13.13'
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
    
    $databases = New-Object System.Collections.ArrayList
    
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
        [void]$databases.Add($defaultDb)
        return , $databases
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
            [void]$databases.Add($db)
        }
    }
    
    if ($databases.Count -eq 0) {
        $defaultDb = [PSCustomObject]@{
            Name    = 'postgres'
            Size_GB = 'Unknown'
            Owner   = 'postgres'
        }
        [void]$databases.Add($defaultDb)
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
        [int]$Port = 5432
    )
    
    $query = "SELECT version();"
    $versionString = Invoke-PostgreSQLQuery -PsqlPath $PsqlPath -Query $query -Port $Port
    
    if ($versionString -match 'EnterpriseDB') {
        return 'Enterprise'
    }
    elseif ($versionString -match 'Crunchy|Timescale|Greenplum') {
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
        [string]$Edition
    )
    
    if ($Edition -eq 'Enterprise') {
        return @{
            LicenseType = 'Commercial'
            NumLicenses = 'Unknown'
        }
    }
    else {
        return @{
            LicenseType = 'PostgreSQL License'
            NumLicenses = 'Unlimited'
        }
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
            
            $edition = Get-PostgreSQLEdition -PsqlPath $PsqlPath -Port $port
            
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
            
            $databases = @(Get-PostgreSQLDatabases -PsqlPath $PsqlPath -Port $port -ConnectionConfig $connectionConfig)
            $isClustered = Test-PostgreSQLClustering -PsqlPath $PsqlPath -Port $port -ConnectionConfig $connectionConfig
        }
        else {
            $errorDetails = 'No database access - authentication failed'
            Write-Verbose "All connection methods failed. Check pg_hba.conf for allowed authentication methods."
            $databases = @([PSCustomObject]@{
                    Name    = 'postgres'
                    Size_GB = 'Unknown'
                    Owner   = 'postgres'
                })
        }
    }
    else {
        $errorDetails = 'PostgreSQL service not running'
        $databases = @([PSCustomObject]@{
                Name    = 'postgres'
                Size_GB = 'Unknown'
                Owner   = 'postgres'
            })
    }
    
    $licenseInfo = Get-PostgreSQLLicenseInfo -Edition $edition
    
    $endTime = Get-Date
    $responseTime = [int](($endTime - $startTime).TotalMilliseconds)
    
    return @{
        Edition          = $edition
        Product          = $versionInfo.FullVersion
        Version          = $versionInfo.Version
        ServerName       = "127.0.0.1"
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
