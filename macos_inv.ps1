param(
    [Parameter(Mandatory = $false)]
    [string]$OutputFolderPath = "/Users/test"
)

function Write-Log {
    param([string]$Message, [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG", "VERBOSE")][string]$Level = "INFO")
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Level - $Message"
    Write-Information $logMessage
    Write-Host $logMessage
}

function Invoke-MacOSCommand {
    param([string]$Command, [string]$ErrorMessage = "Command execution failed")
    try {
        Write-Log "Executing: $Command" -Level DEBUG
        $result = Invoke-Expression $Command 2>&1
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            Write-Log "$ErrorMessage (Exit code: $LASTEXITCODE): $result" -Level WARNING
            return $null
        }
        return $result
    }
    catch {
        Write-Log "$ErrorMessage : $_" -Level WARNING
        return $null
    }
}

function Get-SystemInfo {
    $hostname = Invoke-MacOSCommand "/usr/bin/hostname" "Failed to get hostname"
    $fqdn = Invoke-MacOSCommand "/usr/bin/hostname -f" "Failed to get FQDN" ?? $hostname
    $ipAddress = Invoke-MacOSCommand "/sbin/ifconfig | grep 'inet ' | /usr/bin/grep -v '127.0.0.1' | /usr/bin/head -1 | /usr/bin/awk '{print `$2}'" "Failed to get IP address" ?? "Unknown"
    $arch = Invoke-MacOSCommand "/usr/bin/uname -m" "Failed to get architecture"
    $osVersion = Invoke-MacOSCommand "/usr/bin/sw_vers -productVersion" "Failed to get macOS version"
    $osBuild = Invoke-MacOSCommand "/usr/bin/sw_vers -buildVersion" "Failed to get macOS build"
    $osName = Invoke-MacOSCommand "/usr/bin/sw_vers -productName" "Failed to get macOS name"
    $installDate = Invoke-MacOSCommand "/usr/bin/stat -f ""%Sm"" -t ""%Y-%m-%d %H:%M:%S"" /var/db/.AppleSetupDone" "Failed to get install date"
    
    $bootTimeRaw = Invoke-MacOSCommand "/usr/sbin/sysctl -n kern.boottime" "Failed to get boot time"
    $lastBoot = if ($bootTimeRaw -match 'sec = (\d+)') {
        [DateTimeOffset]::FromUnixTimeSeconds([int]$Matches[1]).LocalDateTime.ToString("yyyy-MM-dd HH:mm:ss")
    }
    else { "Unknown" }
    
    $uuid = Invoke-MacOSCommand "/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/grep 'Hardware UUID' | /usr/bin/awk -F': ' '{print `$2}'" "Failed to get UUID" ?? "Unknown"
    
    return @{
        hostname = $hostname; fqdn = $fqdn; ipAddress = $ipAddress; arch = $arch
        osVersion = $osVersion; osBuild = $osBuild; osName = $osName
        installDate = $installDate; lastBoot = $lastBoot; uuid = $uuid
    }
}

function Get-HardwareInfo {
    param($sysInfo)
    
        # $memoryInfo = system_profiler SPMemoryDataType
        # $slotsList = [System.Collections.Generic.List[psobject]]::new()
        # $currentSlot = $null
        # foreach ($line in $memoryInfo) {
        #     if ($line -match '^\s{8}(\S+):$') {
        #         if ($null -ne $currentSlot) {
        #             $slotsList.Add($currentSlot)
        #         }
        #         $currentSlot = [PSCustomObject]@{
        #             Name         = $Matches[1].Trim()
        #             Size         = 'Unknown'
        #             Type         = 'Unknown'
        #             Speed        = 'Unknown'
        #             Status       = 'Unknown'
        #             Manufacturer = 'Unknown'
        #             PartNumber   = 'Unknown'
        #             SerialNumber = 'Unknown'
        #         }
        #         continue
        #     }
        #     if ($line -match '^\s{10}([^:]+):\s*(.*)') {          
        #         if ($null -ne $currentSlot) {
        #             $key = $Matches[1].Trim()
        #             $value = $Matches[2].Trim()
        #             $propertyName = $key -replace '\s', ''
        #             if ($currentSlot.PSObject.Properties.Name -contains $propertyName) {
        #                 $currentSlot.$propertyName = $value
        #             }
        #         }
        #     }
        # }
        # if ($null -ne $currentSlot) {
        #     $slotsList.Add($currentSlot)
        # }
        # $Slots = $slotsList


    $cpuInfo = Invoke-MacOSCommand "/usr/sbin/system_profiler SPHardwareDataType" "Failed to get hardware info"
    $cpuModel = /usr/sbin/sysctl -n machdep.cpu.brand_string
    $cpuCores = /usr/sbin/sysctl -n hw.physicalcpu_max
    $cpuLogicalProcessors = /usr/sbin/sysctl -n hw.logicalcpu_max
    $currentSpeed = [math]::Round(($(/usr/sbin/sysctl -n hw.cpufrequency_max)) / 1000000)
    $cpuTemp = /usr/sbin/sysctl -n machdep.cpu.thermal.sensor
    $totalMemGB = [math]::Round(($(/usr/sbin/sysctl hw.memsize) -split ' ')[-1] / 1024 / 1024)
    # $slots = @{ Name = $slotsList.name; Size = $dfParts[2]; Type = $dfParts[3]; Speed = $dfParts[4]; Status = ; Manufacturer = ; PartNumber = ; SerialNumber =  }
    
    $model = ($cpuInfo | Where-Object { $_ -match "Model Name:" }) -replace ".*Model Name:\s*", ""
    $serialNumber = ($cpuInfo | Where-Object { $_ -match "Serial Number.*:" }) -replace ".*Serial Number.*:\s*", ""
    $biosVersion = ($cpuInfo | Where-Object { $_ -match "System Firmware Version.*:" }) -replace ".*System Firmware Version.*:\s*", ""
    
    return @{
        FQDN = $sysInfo.fqdn; ServiceTag = $serialNumber; Model = $model; Manufacturer = "Apple Inc."
        BIOS = @{ Manufacturer = "Apple Inc."; Version = $biosVersion; SMBIOSVersion = "Unknown"; ReleaseDate = "Unknown"; SerialNumber = $serialNumber }
        Motherboard = @{ Manufacturer = "Apple Inc."; Product = $model; SerialNumber = $serialNumber; Version = "Unknown" }
        CPU = @{ Name = $cpuModel; Manufacturer = "Apple Inc."; Cores = [int]$cpuCores; LogicalProcessors = [int]$cpuLogicalProcessors; Speed = $currentSpeed; CurrentSpeed = $currentSpeed; Architecture = $sysInfo.arch; ProcessorId = "Unknown"; CpuTemp = $cpuTemp }
        RAM = @{ Total_GB = $totalMemGB }
        LocalDisks = @(Get-DiskInfo)
        SystemDisk = Get-SystemDiskInfo
        Battery = Get-BatteryInfo
    }
}

function Get-DiskInfo {
    $diskList = Invoke-MacOSCommand "/usr/sbin/diskutil list" "Failed to get disk list"
    $dfOutput = Invoke-MacOSCommand "df -h" "Failed to get disk usage information"
    $localDisks = @()
    
    foreach ($line in $diskList) {
        if ($line -match "^/dev/(disk\d+).*:") {
            $currentDisk = $Matches[1]
            $diskInfo = Invoke-MacOSCommand "/usr/sbin/diskutil info $currentDisk" "Failed to get disk info for $currentDisk"
            
            $diskSize = ($diskInfo | Where-Object { $_ -match "Total Size:\s*(.*)" }) -replace ".*Total Size:\s*", "" ?? "Unknown"
            $diskModel = ($diskInfo | Where-Object { $_ -match "Device / Media Name:\s*(.*)" }) -replace ".*Device / Media Name:\s*", "" ?? "Unknown"
            $diskType = ($diskInfo | Where-Object { $_ -match "Protocol:\s*(.*)" }) -replace ".*Protocol:\s*", "" ?? "Unknown"
            
            $partitions = @()
            $partitionList = Invoke-MacOSCommand "/usr/sbin/diskutil list $currentDisk" "Failed to get partitions for $currentDisk"
            
            foreach ($partLine in $partitionList) {
                if ($partLine -match "^\s*\d+:\s+(\S+)\s+(.*?)\s{2,}\*?\s*([0-9.]+\s+[KMGT]B)\s+(disk\d+(?:s\d+)?)$") {
                    $partType, $partName, $partitionSize, $partDevice = $Matches[1..4]
                    
                    $mountInfo = Invoke-MacOSCommand "/usr/sbin/diskutil info $partDevice" "Failed to get mount info for $partDevice"
                    $mountPoint = ($mountInfo | Where-Object { $_ -match "Mount Point:\s*(.*)" }) -replace ".*Mount Point:\s*", "" ?? ""
                    
                    $usage = $null
                    if ($mountPoint -and $mountPoint -ne "Not applicable (no file system)") {
                        $dfLine = $dfOutput | Where-Object { $_ -match ([regex]::Escape($mountPoint) + "$") } | Select-Object -First 1
                        if ($dfLine) {
                            $dfParts = $dfLine -split '\s+' | Where-Object { $_ -ne "" }
                            $usage = @{ Size = $dfParts[1]; Used = $dfParts[2]; Available = $dfParts[3]; UsePercentage = $dfParts[4] }
                        }
                    }
                    
                    $partitions += @{ Name = $partDevice; Size = $partitionSize; Type = $partType; Label = $partName; MountPoint = $mountPoint; FileSystem = $partType; Usage = $usage }
                }
            }
            
            $localDisks += @{ Name = $currentDisk; Size = $diskSize; Type = $diskType; Model = $diskModel; Partitions = $partitions }
        }
    }
    
    Write-Log "Collected information for $($localDisks.Count) disks" -Level INFO
    return $localDisks
}

function Get-SystemDiskInfo {
    $dfOutput = Invoke-MacOSCommand "df -h" "Failed to get disk usage information"
    $rootDisk = $dfOutput | Where-Object { $_ -match " /$" }
    
    if (-not $rootDisk) { return @{} }
    
    $rootParts = $rootDisk -split '\s+'
    $rootDevice = $rootParts[0]
    
    $rootFsType = try { (Invoke-MacOSCommand "mount | grep ' on / '" "").Split('(')[1].Split(',')[0] } catch { "APFS" }
    $diskModel = try {
        $info = Invoke-MacOSCommand "/usr/sbin/diskutil info $rootDevice" ""
        if ($info -match 'Device / Media Name:\s*(.+)') { $matches[1].Trim() } else { $matches[1].Trim() }
    }
    catch { "Macintosh HD" }
    
    function ConvertTo-GB($size) {
        if ($size -match '(\d+(?:\.\d+)?)([KMGT]i?)') {
            $num = [double]$matches[1]
            switch ($matches[2]) {
                { $_ -in 'Ki', 'K' } { $num / 1024 / 1024 }
                { $_ -in 'Mi', 'M' } { $num / 1024 }
                { $_ -in 'Gi', 'G' } { $num }
                { $_ -in 'Ti', 'T' } { $num * 1024 }
                default { $num / 1024 / 1024 }
            }
        }
        else { try { [double]$size / 1024 / 1024 } catch { 0 } }
    }
    
    $sizeGB = [math]::Round((ConvertTo-GB $rootParts[1]), 2)
    $usedGB = [math]::Round((ConvertTo-GB $rootParts[2]), 2)
    $availableGB = [math]::Round((ConvertTo-GB $rootParts[3]), 2)
    $usePercentage = if ($sizeGB -gt 0) { [math]::Round(($usedGB / $sizeGB) * 100, 1) } else { 0 }
    
    $smartHealth = Invoke-MacOSCommand "/usr/sbin/diskutil info $(/usr/sbin/diskutil info / | grep 'Part of Whole' | awk '{print $4}') | grep 'SMART Status' | awk -F': ' '{print $2}' | xargs" "Failed to get SMART status"
    
    return @{
        Device = $rootDevice; Model = $diskModel; Size_GB = $sizeGB; Used_GB = $usedGB; Available_GB = $availableGB
        UsePercentage = "$usePercentage%"; FreeSpace_GB = $availableGB; TotalSpace_GB = $sizeGB
        MountPoint = "/"; FileSystem = $rootFsType; DriveType = "Fixed"
        Smart_HealthStatus = $smartHealth; Smart_OperationalStatus = "OK"; Smart_PredictFailure = "False"
        Smart_MediaType = "Unknown"; Smart_Temperature = "N/A"
    }
}

function Get-BatteryInfo {
    $powerInfo = Invoke-MacOSCommand "system_profiler SPPowerDataType" "Failed to get power information"
    $hasBattery = $powerInfo -match "Battery Information:"
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    $batteryInfo = @{
        Present = $hasBattery; Charge_Remaining = if ($hasBattery) { "0%" } else { $null }
        Status = if ($hasBattery) { 0 } else { $null }; Estimated_Runtime = if ($hasBattery) { 0 } else { $null }
        Power_Online = if ($hasBattery) { $false } else { $null }; Is_Charging = if ($hasBattery) { $false } else { $null }
        Is_Critical = if ($hasBattery) { $false } else { $null }; Design_Capacity = if ($hasBattery) { 0 } else { $null }
        Full_Charge_Capacity = if ($hasBattery) { 0 } else { $null }; Time_On_Battery = if ($hasBattery) { 0 } else { $null }
        Time_To_Full_Charge = if ($hasBattery) { 0 } else { $null }; CollectionTime = $timestamp
    }
    
    if ($hasBattery) {
        $pmsetInfo = Invoke-MacOSCommand "pmset -g batt" "Failed to get battery status"
        if ($pmsetInfo) {
            foreach ($line in $pmsetInfo) {
                if ($line -match "(\d+)%.*'([^']+)'") {
                    $percentage = [int]$Matches[1]
                    $timeRemaining = $Matches[2]
                    
                    $batteryInfo.Charge_Remaining = "$percentage%"
                    $batteryInfo.Is_Critical = ($percentage -lt 10)
                    
                    if ($timeRemaining -match "(\d+):(\d+)") {
                        $totalMinutes = ([int]$Matches[1] * 60) + [int]$Matches[2]
                        if ($line -match "discharging") {
                            $batteryInfo.Estimated_Runtime = $totalMinutes; $batteryInfo.Status = 1; $batteryInfo.Is_Charging = $false
                        }
                        elseif ($line -match "charging") {
                            $batteryInfo.Time_To_Full_Charge = $totalMinutes; $batteryInfo.Status = 2; $batteryInfo.Is_Charging = $true
                        }
                    }
                }
            }
        }
    }
    
    return $batteryInfo
}

function Get-NetworkInfo {
    param($sysInfo)
    
    $primaryInterface = Invoke-MacOSCommand "route get default | grep interface | awk '{print `$2}'" "Failed to get primary interface"
    
    $adapterInfo = @{
        AdapterName = $primaryInterface ?? "Unknown"; Status = @($null, $null, $null, 2, $null, $null)
        MacAddress = "Unknown"; IPAddress = $sysInfo.ipAddress; SubnetMask = "255.255.255.0"
        DefaultGateway = "Unknown"; DNSServerSearchOrder = @("Unknown"); ArpTable = @()
    }
    
    if ($primaryInterface) {
        $macAddress = Invoke-MacOSCommand "ifconfig $primaryInterface | grep ether | awk '{print `$2}'" "Failed to get MAC address"
        if ($macAddress) { $adapterInfo.MacAddress = $macAddress.ToUpper().Replace(':', '-') }
        
        $netmask = Invoke-MacOSCommand "ifconfig $primaryInterface | grep 'inet ' | awk '{print `$4}'" "Failed to get netmask"
        if ($netmask) { $adapterInfo.SubnetMask = $netmask }
        
        $defaultGateway = Invoke-MacOSCommand "route get default | grep gateway | awk '{print `$2}'" "Failed to get default gateway"
        if ($defaultGateway) { $adapterInfo.DefaultGateway = $defaultGateway }
        
        $dnsServers = Invoke-MacOSCommand "scutil --dns | grep 'nameserver\[[0-9]*\]' | awk '{print `$3}'" "Failed to get DNS servers"
        if ($dnsServers) { $adapterInfo.DNSServerSearchOrder = @($dnsServers) }
        
        $arpEntries = Invoke-MacOSCommand "arp -an" "Failed to get ARP table"
        if ($arpEntries) {
            $arpTable = @()
            foreach ($entry in $arpEntries) {
                if ($entry -match '\((\d+\.\d+\.\d+\.\d+)\)\s+at\s+([0-9a-f:]+)') {
                    $arpTable += @{ IPAddress = $Matches[1]; MACAddress = $Matches[2].ToUpper().Replace(':', '-') }
                }
            }
            if ($arpTable.Count -gt 0) { $adapterInfo.ArpTable = $arpTable }
        }
    }
    
    return @{ FQDN = $sysInfo.fqdn; Adapters = $adapterInfo; IpAddress = $sysInfo.ipAddress }
}

function Get-SoftwareInfo {
    param($sysInfo)
    
    $installedSoftware = @()
    $appInfo = Invoke-MacOSCommand "system_profiler SPApplicationsDataType" "Failed to get installed applications"
    
    if ($appInfo) {
        $currentApp = @{}
        foreach ($line in $appInfo) {
            if ($line -match "^\s*([^:]+):$") {
                if ($currentApp.Name) { $installedSoftware += $currentApp }
                $currentApp = @{ Name = $Matches[1].Trim(); Version = "Unknown"; Vendor = "Unknown"; InstallDate = "Unknown" }
            }
            elseif ($line -match "Version:\s*(.*)") { $currentApp.Version = $Matches[1].Trim() }
            elseif ($line -match "Obtained from:\s*(.*)") { $currentApp.Vendor = $Matches[1].Trim() }
            elseif ($line -match "Last Modified:\s*(.*)") { $currentApp.InstallDate = $Matches[1].Trim() }
        }
        if ($currentApp.Name) { $installedSoftware += $currentApp }
    }
    
    $brewList = Invoke-MacOSCommand "brew list --formula 2>/dev/null" "Homebrew not available"
    if ($brewList) {
        foreach ($package in $brewList) {
            if ($package.Trim()) {
                $version = Invoke-MacOSCommand "brew list --versions $package 2>/dev/null" "Failed to get version for $package"
                $versionString = if ($version -match "$package (.+)") { $Matches[1] } else { "Unknown" }
                $installedSoftware += @{ Name = $package.Trim(); Version = $versionString; Vendor = "Homebrew"; InstallDate = "Unknown" }
            }
        }
    }
    
    Write-Log "Collected information for $($installedSoftware.Count) software packages" -Level INFO
    return @{ FQDN = $sysInfo.fqdn; InstalledSoftware = @($installedSoftware) }
}

function Get-DeviceInfo {
    param($sysInfo)
    
    $usbDevices = Invoke-MacOSCommand "system_profiler SPUSBDataType" "Failed to get USB devices"
    $devices = @()
    
    if ($usbDevices) {
        $currentDevice = @{}
        foreach ($line in $usbDevices) {
            if ($line -match "^\s*([^:]+):$") {
                if ($currentDevice.DeviceName) { $devices += $currentDevice }
                $currentDevice = @{
                    DeviceName = $Matches[1].Trim(); DeviceID = "Unknown"; Description = $Matches[1].Trim()
                    Manufacturer = "Unknown"; Status = "OK"; PNPClass = "USB"; Present = $true
                }
            }
            elseif ($line -match "Product ID:\s*(.*)") { $currentDevice.DeviceID = $Matches[1].Trim() }
            elseif ($line -match "Vendor ID:\s*(.*)") { $currentDevice.Manufacturer = $Matches[1].Trim() }
        }
        if ($currentDevice.DeviceName) { $devices += $currentDevice }
    }
    
    return @{ FQDN = $sysInfo.fqdn; ConnectedDevices = $devices }
}

function Get-MacOSInventory {
    try {
        $ComputerName = hostname
        Write-Log "Starting macOS inventory collection for: $ComputerName" -Level INFO
        
        $sysInfo = Get-SystemInfo
        $hardware = Get-HardwareInfo $sysInfo
        $network = Get-NetworkInfo $sysInfo
        $software = Get-SoftwareInfo $sysInfo
        $devices = Get-DeviceInfo $sysInfo
        
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

        $inventory = @{
            SystemInfo = @{
                IpAddress = $sysInfo.ipAddress; FQDN = $sysInfo.fqdn; Domain = "N/A"
                DomainRole = 0; PartOfDomain = $false; Workgroup = "N/A"; CurrentUser = $env:USER; UUID = $sysInfo.uuid
                OSInfo = @{
                    Name = $sysInfo.osName; Version = $sysInfo.osVersion; BuildNumber = $sysInfo.osBuild
                    InstallDate = $sysInfo.installDate; LastBootTime = $sysInfo.lastBoot; Architecture = $sysInfo.arch
                    SystemDrive = "/"; WindowsDirectory = "N/A"
                }
            }
            Hardware   = $hardware
            Network    = $network
            Software   = $software
            Devices    = $devices
            EventLogs  = @{ FQDN = $sysInfo.fqdn; ScanPeriodDays = 30; Statistics = @{}; CollectionTime = $timestamp }
            ScanTime   = $timestamp
        }
        
        if (-not (Test-Path -Path $OutputFolderPath)) {
            New-Item -ItemType Directory -Path $OutputFolderPath -Force | Out-Null
        }
        
        
        $sections = @{ 'SystemInfo' = $inventory.SystemInfo; 'Hardware' = $inventory.Hardware; 'Network' = $inventory.Network; 'Software' = $inventory.Software; 'Devices' = $inventory.Devices; 'EventLogs' = $inventory.EventLogs }
        
        foreach ($section in $sections.Keys) {
            $fileName = Join-Path $OutputFolderPath "discover-$($sysInfo.uuid)_${section}-$timestamp.json"
            $sections[$section] | ConvertTo-Json -Depth 10 | Out-File -FilePath $fileName -Encoding UTF8
            Write-Log "Exported $section to $fileName" -Level INFO
        }
        
        return $inventory
    }
    catch {
        Write-Log "Error during inventory collection: $_" -Level ERROR
        Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
        return $false
    }
}

try {
    Write-Log "Starting macOS inventory collection" -Level INFO
    $result = Get-MacOSInventory
    if ($result) {
        Write-Log "Inventory collection completed successfully" -Level INFO
        return $result
    }
    else {
        Write-Log "Inventory collection failed" -Level ERROR
        return $false
    }
}
catch {
    Write-Log "Script execution failed: $_" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    return $false
}
