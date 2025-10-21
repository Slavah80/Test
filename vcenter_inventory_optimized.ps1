# Usage
#.\vcenter_inventory.ps1 -ComputerName "dc1plxvcs001.nr.ad.newellco.com" -OutputFolderPath "c:\temp\vCenter_Inventory" -Credential $cred
# Run all vCenter servers (default behavior):
#.\vcenter_inventory.ps1
# Or specify specific servers:
#.\vcenter_inventory.ps1 -ComputerName @("dc1plxvcs001.nr.ad.newellco.com", "dc2plxvcs001.nr.ad.newellco.com")

param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string[]]$ComputerName = @(
        "dc1plxvcs001.nr.ad.newellco.com",  # DC1 (Dev/Test) - 10.22.32.20
        "dc2plxvcs001.nr.ad.newellco.com",  # DC2 (Prod) - 10.24.96.20
        "dc2plxvcs004.nr.ad.newellco.com",  # Oracle Apps (Prod and Dev) - 10.25.105.1
        "dc2plxvcs003.nr.ad.newellco.com",  # Oracle DB (Prod and Dev) - 10.25.105.0
        "dc2pwnvcs002.nr.ad.newellco.com"   # Edge (All remote sites) - 10.24.96.21
    ),

    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$OutputFolderPath = "C:\Program Files\AithenticStandaloneAgent\Service\uploads",

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'Continue'

function Test-PowerCLIModule {
    try {
        # Import the necessary PowerCLI modules that are already installed
        $modulesToImport = @(
            'VMware.VimAutomation.Core',
            'VMware.VimAutomation.Common',
            'VMware.VimAutomation.Cis.Core',
            'VMware.VimAutomation.Storage',
            'VMware.VimAutomation.Vds'
        )

        foreach ($module in $modulesToImport) {
            if (Get-Module -ListAvailable -Name $module) {
                Import-Module $module -ErrorAction Stop
                Write-Verbose "Imported module: $module"
            } else {
                Write-Warning "Module $module not found, but continuing..."
            }
        }

        Write-ColorOutput "PowerCLI modules loaded successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to import PowerCLI modules: $($_.Exception.Message)"
        return $false
    }
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [ConsoleColor]$ForegroundColor = 'White'
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Connect-ToVCenter {
    param(
        [string]$Server,
        [System.Management.Automation.PSCredential]$Cred,
        [bool]$IgnoreCerts = $true
    )

    try {
        if ($IgnoreCerts) {
            Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -ErrorAction SilentlyContinue
            Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false -ErrorAction SilentlyContinue
        }

        Write-ColorOutput "Connecting to vCenter Server: $Server" -ForegroundColor Yellow
        $connection = Connect-VIServer -Server $Server -Credential $Cred -ErrorAction Stop
        Write-ColorOutput "Successfully connected to $($connection.Name)" -ForegroundColor Green
        return $connection
    }
    catch {
        throw "Failed to connect to vCenter Server '$Server': $($_.Exception.Message)"
    }
}

function Get-VMInventoryData {
    param([string]$ServerName)

    try {
        Write-ColorOutput "Retrieving Virtual Machine inventory..." -ForegroundColor Yellow

        # Get all VMs at once
        $vms = Get-VM -ErrorAction Stop
        $totalVMs = $vms.Count

        if ($totalVMs -eq 0) {
            Write-ColorOutput "No VMs found" -ForegroundColor Yellow
            return @()
        }

        Write-ColorOutput "Processing $totalVMs VMs..." -ForegroundColor Yellow

        # OPTIMIZATION: Batch retrieve all VM views at once
        $vmViews = @{}
        $allViews = Get-View -VIObject $vms -ErrorAction SilentlyContinue
        for ($i = 0; $i -lt $vms.Count; $i++) {
            if ($allViews[$i]) {
                $vmViews[$vms[$i].Id] = $allViews[$i]
            }
        }

        # OPTIMIZATION: Batch retrieve all VMGuest info at once
        $vmGuests = @{}
        $allGuests = $vms | Get-VMGuest -ErrorAction SilentlyContinue
        foreach ($guest in $allGuests) {
            $vmGuests[$guest.VMId] = $guest
        }

        # OPTIMIZATION: Create datastore cache to avoid repeated Get-Datastore calls
        $datastoreCache = @{}
        $allDatastores = Get-Datastore -ErrorAction SilentlyContinue
        foreach ($ds in $allDatastores) {
            $datastoreCache[$ds.Id] = $ds.Name
        }

        # OPTIMIZATION: Batch retrieve all hardware and network info
        $allHardware = @{}
        $allNetwork = @{}

        # Process all VMs in parallel using ForEach-Object -Parallel (PS 7+) or sequentially but optimized
        $vmData = @()
        $currentVM = 0

        foreach ($vm in $vms) {
            $currentVM++
            $percentComplete = if ($totalVMs -gt 0) { ($currentVM / $totalVMs) * 100 } else { 0 }
            Write-Progress -Activity "Processing VMs" -Status "Processing $($vm.Name) ($currentVM/$totalVMs)" -PercentComplete $percentComplete

            try {
                # Use cached view
                $vmView = $vmViews[$vm.Id]

                # Use cached guest
                $vmGuest = $vmGuests[$vm.Id]

                # Get hardware and network (these are relatively fast, per-VM calls)
                if (-not $allHardware.ContainsKey($vm.Id)) {
                    $vmHardware = $vm | Get-HardDisk -ErrorAction SilentlyContinue
                    $allHardware[$vm.Id] = $vmHardware
                } else {
                    $vmHardware = $allHardware[$vm.Id]
                }

                if (-not $allNetwork.ContainsKey($vm.Id)) {
                    $vmNetwork = $vm | Get-NetworkAdapter -ErrorAction SilentlyContinue
                    $allNetwork[$vm.Id] = $vmNetwork
                } else {
                    $vmNetwork = $allNetwork[$vm.Id]
                }

                # Build disk array
                $diskArray = @()
                foreach ($disk in $vmHardware) {
                    $diskArray += @{
                        name          = $disk.Name
                        capacity_gb   = [math]::Round($disk.CapacityGB, 2)
                        filename      = $disk.Filename
                        storage_format = $disk.StorageFormat
                        disk_type     = $disk.DiskType
                    }
                }

                # Build network array
                $networkArray = @()
                foreach ($nic in $vmNetwork) {
                    $networkArray += @{
                        name         = $nic.Name
                        type         = $nic.Type
                        network_name = $nic.NetworkName
                        mac_address  = $nic.MacAddress
                        connected    = $nic.ConnectionState.Connected
                    }
                }

                # OPTIMIZATION: Use cached datastore names
                $datastoreNames = @()
                foreach ($dsId in $vm.DatastoreIdList) {
                    if ($datastoreCache.ContainsKey($dsId)) {
                        $datastoreNames += $datastoreCache[$dsId]
                    }
                }
                $datastoreString = $datastoreNames -join ', '

                $vmObject = @{
                    name                   = $vm.Name
                    uuid                   = $vm.ExtensionData.Config.Uuid
                    power_state            = $vm.PowerState
                    num_cpu                = $vm.NumCpu
                    cores_per_socket       = $vm.CoresPerSocket
                    memory_gb              = [math]::Round($vm.MemoryGB, 2)
                    used_space_gb          = [math]::Round($vm.UsedSpaceGB, 2)
                    provisioned_space_gb   = [math]::Round($vm.ProvisionedSpaceGB, 2)
                    guest_os               = $vm.Guest.OSFullName
                    vm_host                = $vm.VMHost.Name
                    cluster                = if ($vm.VMHost.Parent.Name) { $vm.VMHost.Parent.Name } else { 'N/A' }
                    datastore              = $datastoreString
                    vmware_tools           = $vm.ExtensionData.Guest.ToolsStatus
                    ip_address             = if ($vmGuest.IPAddress) { $vmGuest.IPAddress -join ', ' } else { 'N/A' }
                    guest_hostname         = if ($vmGuest.HostName) { $vmGuest.HostName } else { 'N/A' }
                    create_date            = if ($vm.CreateDate) { $vm.CreateDate.ToString('yyyyMMdd-HHmmss') } else { 'N/A' }
                    hardware_version       = $vm.HardwareVersion
                    annotation             = if ($vm.Notes) { $vm.Notes } else { 'N/A' }
                    folder                 = $vm.Folder.Name
                    resource_pool          = $vm.ResourcePool.Name
                    disks                  = $diskArray
                    network_adapters       = $networkArray
                    snapshot               = if ($vmView.Snapshot) { $vmView.Snapshot } else { 'N/A' }
                    guest_heartbeat_status = if ($vmView.GuestHeartbeatStatus) { $vmView.GuestHeartbeatStatus } else { 'N/A' }
                    overall_status         = if ($vmView.OverallStatus) { $vmView.OverallStatus } else { 'N/A' }
                    config_status          = if ($vmView.ConfigStatus) { $vmView.ConfigStatus } else { 'N/A' }
                    alarm_actions_enabled  = if ($vmView.AlarmActionsEnabled) { $vmView.AlarmActionsEnabled } else { 'N/A' }
                }

                $vmData += $vmObject
            }
            catch {
                Write-Warning "Failed to process VM '$($vm.Name)': $($_.Exception.Message)"
            }
        }

        Write-Progress -Activity "Processing VMs" -Completed
        Write-ColorOutput "Successfully processed $($vmData.Count) Virtual Machines" -ForegroundColor Green
        return $vmData
    }
    catch {
        throw "Failed to retrieve VM inventory: $($_.Exception.Message)"
    }
}

function Get-HostInventoryData {
    try {
        Write-ColorOutput "Retrieving ESXi Host inventory..." -ForegroundColor Yellow
        $hosts = Get-VMHost -ErrorAction Stop

        if ($hosts.Count -eq 0) {
            Write-ColorOutput "No hosts found" -ForegroundColor Yellow
            return @()
        }

        # OPTIMIZATION: Batch retrieve all host views
        $hostViews = @{}
        $allHostViews = Get-View -VIObject $hosts -ErrorAction SilentlyContinue
        for ($i = 0; $i -lt $hosts.Count; $i++) {
            if ($allHostViews[$i]) {
                $hostViews[$hosts[$i].Id] = $allHostViews[$i]
            }
        }

        # OPTIMIZATION: Pre-fetch all datastores once
        $allDatastores = Get-Datastore -ErrorAction SilentlyContinue

        $hostData = @()

        foreach ($vmHost in $hosts) {
            try {
                $hostView = $hostViews[$vmHost.Id]

                # Get network info (keep these as they're per-host specific)
                $hostVirtualSwitches = $vmHost | Get-VirtualSwitch -Standard -ErrorAction SilentlyContinue
                $hostVMKernelAdapters = $vmHost | Get-VMHostNetworkAdapter -VMKernel -ErrorAction SilentlyContinue
                $hostPhysicalAdapters = $vmHost | Get-VMHostNetworkAdapter -Physical -ErrorAction SilentlyContinue

                # OPTIMIZATION: Filter datastores for this host instead of calling Get-Datastore per host
                $datastoreArray = @()
                $hostDatastores = $allDatastores | Where-Object { $_.ExtensionData.Host.Key -contains $vmHost.ExtensionData.MoRef.Value }

                foreach ($ds in $hostDatastores) {
                    $datastoreArray += @{
                        name          = $ds.Name
                        type          = $ds.Type
                        capacity_gb   = [math]::Round($ds.CapacityGB, 2)
                        free_space_gb = [math]::Round($ds.FreeSpaceGB, 2)
                        accessible    = ($ds.State -eq 'Available')
                    }
                }

                $hostObject = @{
                    name              = $vmHost.Name
                    uuid              = $vmHost.ExtensionData.Hardware.SystemInfo.Uuid
                    connection_state  = $vmHost.ConnectionState
                    power_state       = $vmHost.PowerState
                    version           = $vmHost.Version
                    build             = $vmHost.Build
                    manufacturer      = $vmHost.Manufacturer
                    model             = $vmHost.Model
                    processor_type    = $vmHost.ProcessorType
                    num_cpu           = $vmHost.NumCpu
                    cpu_total_mhz     = $vmHost.CpuTotalMhz
                    cpu_usage_mhz     = $vmHost.CpuUsageMhz
                    memory_total_gb   = [math]::Round($vmHost.MemoryTotalGB, 2)
                    memory_usage_gb   = [math]::Round($vmHost.MemoryUsageGB, 2)
                    max_evc_mode      = if ($vmHost.MaxEVCMode) { $vmHost.MaxEVCMode } else { 'N/A' }
                    cluster           = if ($vmHost.Parent.Name) { $vmHost.Parent.Name } else { 'N/A' }
                    datacenter        = $vmHost.Datacenter.Name
                    network_info      = @{
                        virtual_switches = ($hostVirtualSwitches | Measure-Object).Count
                        vmkernel_ports   = ($hostVMKernelAdapters | Measure-Object).Count
                        physical_nics    = ($hostPhysicalAdapters | Measure-Object).Count
                    }
                    datastores        = $datastoreArray
                    maintenance_mode  = $vmHost.ConnectionState -eq 'Maintenance'
                    license_key       = if ($vmHost.LicenseKey) { $vmHost.LicenseKey } else { 'N/A' }
                    time_zone         = if ($vmHost.TimeZone) { $vmHost.TimeZone.Name } else { 'N/A' }
                    overall_status    = if ($hostView.OverallStatus) { $hostView.OverallStatus } else { 'N/A' }
                    config_status     = if ($hostView.ConfigStatus) { $hostView.ConfigStatus } else { 'N/A' }
                }

                $hostData += $hostObject
            }
            catch {
                Write-Warning "Failed to process Host '$($vmHost.Name)': $($_.Exception.Message)"
            }
        }

        Write-ColorOutput "Successfully processed $($hostData.Count) ESXi Hosts" -ForegroundColor Green
        return $hostData
    }
    catch {
        throw "Failed to retrieve Host inventory: $($_.Exception.Message)"
    }
}

function Get-InfrastructureInventoryData {
    try {
        Write-ColorOutput "Retrieving Infrastructure inventory..." -ForegroundColor Yellow

        $infraData = @{
            clusters             = @()
            datastores           = @()
            networks             = @()
            virtual_switches     = @()
            resource_pools       = @()
            folders              = @()
            datacenters          = @()
            distributed_switches = @()
            port_groups          = @()
            vcenter_info         = @{}
        }

        # OPTIMIZATION: Get all infrastructure components at once
        $clusters = Get-Cluster -ErrorAction SilentlyContinue
        $datastores = Get-Datastore -ErrorAction SilentlyContinue
        $networks = Get-VirtualNetwork -ErrorAction SilentlyContinue
        $virtualSwitches = Get-VirtualSwitch -Standard -ErrorAction SilentlyContinue
        $resourcePools = Get-ResourcePool -ErrorAction SilentlyContinue
        $folders = Get-Folder -ErrorAction SilentlyContinue
        $datacenters = Get-Datacenter -ErrorAction SilentlyContinue

        # OPTIMIZATION: Create lookup tables for counts to avoid repeated Get-* calls
        $clusterHostCount = @{}
        $clusterVMCount = @{}
        $dcClusterCount = @{}
        $dcHostCount = @{}
        $dcVMCount = @{}
        $dcDatastoreCount = @{}

        # Pre-calculate all hosts and VMs
        $allHosts = Get-VMHost -ErrorAction SilentlyContinue
        $allVMs = Get-VM -ErrorAction SilentlyContinue

        # Build cluster lookup tables
        foreach ($cluster in $clusters) {
            $clusterHostCount[$cluster.Id] = ($allHosts | Where-Object { $_.ParentId -eq $cluster.Id }).Count
            $clusterVMCount[$cluster.Id] = ($allVMs | Where-Object { $_.VMHost.ParentId -eq $cluster.Id }).Count
        }

        # Build datacenter lookup tables
        foreach ($dc in $datacenters) {
            $dcClusters = $clusters | Where-Object { $_.Uid -like "*$($dc.Name)*" }
            $dcClusterCount[$dc.Id] = $dcClusters.Count
            $dcHostCount[$dc.Id] = ($allHosts | Where-Object { $_.Uid -like "*$($dc.Name)*" }).Count
            $dcVMCount[$dc.Id] = ($allVMs | Where-Object { $_.Uid -like "*$($dc.Name)*" }).Count
            $dcDatastoreCount[$dc.Id] = ($datastores | Where-Object { $_.Uid -like "*$($dc.Name)*" }).Count
        }

        # Clusters
        foreach ($cluster in $clusters) {
            $infraData.clusters += @{
                name                 = $cluster.Name
                total_cpu_mhz        = $cluster.CpuTotalMhz
                total_memory_gb      = [math]::Round($cluster.MemoryTotalGB, 2)
                num_hosts            = $clusterHostCount[$cluster.Id]
                num_vms              = $clusterVMCount[$cluster.Id]
                ha_enabled           = $cluster.HAEnabled
                drs_enabled          = $cluster.DrsEnabled
                drs_automation_level = $cluster.DrsAutomationLevel
                evc_mode             = if ($cluster.EVCMode) { $cluster.EVCMode } else { 'N/A' }
            }
        }

        # Datastores
        foreach ($datastore in $datastores) {
            $infraData.datastores += @{
                name                 = $datastore.Name
                type                 = $datastore.Type
                file_system_version  = $datastore.FileSystemVersion
                capacity_gb          = [math]::Round($datastore.CapacityGB, 2)
                free_space_gb        = [math]::Round($datastore.FreeSpaceGB, 2)
                percent_free         = if ($datastore.CapacityGB -gt 0) { [math]::Round(($datastore.FreeSpaceGB / $datastore.CapacityGB) * 100, 2) } else { 0 }
                accessible           = ($datastore.State -eq 'Available')
                multiple_host_access = $datastore.MultipleHostAccess
                datacenter           = $datastore.Datacenter.Name
            }
        }

        # Networks
        foreach ($network in $networks) {
            $infraData.networks += @{
                name                = $network.Name
                vlan_id             = if ($network.VLanId) { $network.VLanId } else { 'N/A' }
                num_ports_available = if ($network.NumPortsAvailable) { $network.NumPortsAvailable } else { 'N/A' }
                num_ports           = if ($network.NumPorts) { $network.NumPorts } else { 'N/A' }
                ip_pool_name        = if ($network.IpPoolName) { $network.IpPoolName } else { 'N/A' }
                ip_pool_id          = if ($network.IpPoolId) { $network.IpPoolId } else { 'N/A' }
                network_type        = if ($network.NetworkType) { $network.NetworkType } else { 'N/A' }
            }
        }

        # VirtualSwitches (Standard switches only to avoid distributed switch warnings)
        foreach ($VirtualSwitchItem in $virtualSwitches) {
            $infraData.virtual_switches += @{
                name      = $VirtualSwitchItem.Name
                num_ports = if ($VirtualSwitchItem.NumPorts) { $VirtualSwitchItem.NumPorts } else { 'N/A' }
                mtu       = if ($VirtualSwitchItem.Mtu) { $VirtualSwitchItem.Mtu } else { 'N/A' }
            }
        }

        # Resource Pools
        foreach ($rp in $resourcePools) {
            $infraData.resource_pools += @{
                name                = $rp.Name
                cpu_reservation_mhz = $rp.CpuReservationMhz
                cpu_limit_mhz       = if ($rp.CpuLimitMhz -eq -1) { 'Unlimited' } else { $rp.CpuLimitMhz }
                mem_reservation_gb  = [math]::Round($rp.MemReservationGB, 2)
                mem_limit_gb        = if ($rp.MemLimitGB -eq -1) { 'Unlimited' } else { [math]::Round($rp.MemLimitGB, 2) }
                num_cpu_shares      = $rp.NumCpuShares
                num_mem_shares      = $rp.NumMemShares
            }
        }

        # Folders
        foreach ($folder in $folders) {
            $infraData.folders += @{
                name   = $folder.Name
                type   = $folder.Type
                path   = $folder.Name
                parent = if ($folder.Parent) { $folder.Parent.Name } else { 'N/A' }
            }
        }

        # Datacenters
        foreach ($dc in $datacenters) {
            $infraData.datacenters += @{
                name           = $dc.Name
                num_clusters   = $dcClusterCount[$dc.Id]
                num_hosts      = $dcHostCount[$dc.Id]
                num_vms        = $dcVMCount[$dc.Id]
                num_datastores = $dcDatastoreCount[$dc.Id]
                parent_folder  = if ($dc.ParentFolder) { $dc.ParentFolder.Name } else { 'N/A' }
            }
        }

        # Distributed Switches
        try {
            $distributedSwitches = Get-VDSwitch -ErrorAction SilentlyContinue
            foreach ($vds in $distributedSwitches) {
                $infraData.distributed_switches += @{
                    name           = $vds.Name
                    version        = $vds.Version
                    num_ports      = $vds.NumPorts
                    vendor         = $vds.Vendor
                    mtu            = $vds.Mtu
                    datacenter     = if ($vds.Datacenter) { $vds.Datacenter.Name } else { 'N/A' }
                    extension_data = @{
                        config_version        = $vds.ExtensionData.Config.ConfigVersion
                        num_standalone_ports  = $vds.ExtensionData.Config.NumStandalonePorts
                    }
                }
            }
        }
        catch {
            Write-Warning "Could not retrieve Distributed Switches: $($_.Exception.Message)"
        }

        # Port Groups (both standard and distributed)
        try {
            $portGroups = Get-VirtualPortGroup -ErrorAction SilentlyContinue
            foreach ($pg in $portGroups) {
                $infraData.port_groups += @{
                    name           = $pg.Name
                    vlan_id        = if ($pg.VLanId) { $pg.VLanId } else { 'N/A' }
                    virtual_switch = if ($pg.VirtualSwitch) { $pg.VirtualSwitch.Name } else { 'N/A' }
                    port           = if ($pg.Port) { $pg.Port } else { 'N/A' }
                }
            }

            # Add Distributed Port Groups
            $distributedPortGroups = Get-VDPortgroup -ErrorAction SilentlyContinue
            foreach ($dpg in $distributedPortGroups) {
                $infraData.port_groups += @{
                    name           = $dpg.Name
                    vlan_id        = if ($dpg.VlanConfiguration) { $dpg.VlanConfiguration.VlanId } else { 'N/A' }
                    virtual_switch = if ($dpg.VDSwitch) { $dpg.VDSwitch.Name } else { 'N/A' }
                    port           = 'Distributed'
                    num_ports      = if ($dpg.NumPorts) { $dpg.NumPorts } else { 'N/A' }
                    port_binding   = if ($dpg.PortBinding) { $dpg.PortBinding } else { 'N/A' }
                }
            }
        }
        catch {
            Write-Warning "Could not retrieve Port Groups: $($_.Exception.Message)"
        }

        # vCenter Server Information
        try {
            $vCenterService = $Global:DefaultVIServers | Select-Object -First 1
            if ($vCenterService) {
                $serviceInstance = Get-View ServiceInstance
                $aboutInfo = $serviceInstance.Content.About

                $infraData.vcenter_info = @{
                    name                      = $vCenterService.Name
                    version                   = $aboutInfo.Version
                    build                     = $aboutInfo.Build
                    full_name                 = $aboutInfo.FullName
                    api_version               = $aboutInfo.ApiVersion
                    api_type                  = $aboutInfo.ApiType
                    license_product_name      = $aboutInfo.LicenseProductName
                    license_product_version   = $aboutInfo.LicenseProductVersion
                    instance_uuid             = $aboutInfo.InstanceUuid
                    os_type                   = $aboutInfo.OsType
                    product_line_id           = $aboutInfo.ProductLineId
                    vendor                    = $aboutInfo.Vendor
                    locale_version            = $aboutInfo.LocaleVersion
                    locale_build              = $aboutInfo.LocaleBuild
                    is_connected              = $vCenterService.IsConnected
                    service_uri               = $vCenterService.ServiceUri
                    port                      = $vCenterService.Port
                }
            }
        }
        catch {
            Write-Warning "Could not retrieve vCenter Server information: $($_.Exception.Message)"
        }

        Write-ColorOutput "Successfully processed Infrastructure components" -ForegroundColor Green
        return $infraData
    }
    catch {
        throw "Failed to retrieve Infrastructure inventory: $($_.Exception.Message)"
    }
}

try {
    Write-ColorOutput "Starting vCenter Inventory Collection..." -ForegroundColor Cyan
    Write-ColorOutput "Running on: $env:COMPUTERNAME" -ForegroundColor White

    if (-not (Test-PowerCLIModule)) {
        throw "PowerCLI module could not be loaded"
    }

    if (-not $ComputerName -or $ComputerName.Count -eq 0) {
        $inputServer = Read-Host "Enter vCenter Server FQDN or IP"
        $ComputerName = @($inputServer)
    }

    if (-not $Credential) {
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'nr.ad.newellco.com\svcVCenterAI', (ConvertTo-SecureString "KfAhi!#6z``bdMj?'I!" -AsPlainText -Force)
        #$Credential = Get-Credential -Message "Enter vCenter credentials"
    }

    # Initialize overall summary tracking
    $overallSummary = @{
        total_servers_processed = 0
        successful_servers = @()
        failed_servers = @()
        collection_start_time = Get-Date
        total_vms_all_servers = 0
        total_hosts_all_servers = 0
    }

    # Loop through each computer name
    foreach ($currentServer in $ComputerName) {
        Write-ColorOutput "Processing vCenter Server: $currentServer" -ForegroundColor Cyan
        $overallSummary.total_servers_processed++

        try {
            $connection = Connect-ToVCenter -Server $currentServer -Cred $Credential -IgnoreCerts $true

            Write-ColorOutput "Connected to vCenter: $($connection.Name)" -ForegroundColor White
            Write-ColorOutput "Version: $($connection.Version)" -ForegroundColor White
            Write-ColorOutput "Build: $($connection.Build)" -ForegroundColor White

            # Create server-specific identifier for file naming
            $serverIdentifier = $currentServer -replace '[\\/:*?"<>|]', '_' -replace '\.', '_'
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $outputDir = $OutputFolderPath

            # Get the UUID of the host generating this inventory
            try {
                $hostUuid = (Get-CimInstance -Class Win32_ComputerSystemProduct).UUID.ToLower()
            }
            catch {
                # Fallback to hostname-based identifier if hardware UUID is not available
                $hostUuid = ([System.Environment]::MachineName + "-" + (Get-Date -Format 'yyyyMMdd')).ToLower()
            }

            # Initialize inventories with empty arrays for error handling
            $vmInventory = @()
            $hostInventory = @()
            $infraInventory = @{}

            # Collect Infrastructure Inventory (vCenter and infrastructure components first)
            try {
                Write-ColorOutput "Gathering vCenter and Infrastructure inventory..." -ForegroundColor Yellow
                $infraInventory = Get-InfrastructureInventoryData
            }
            catch {
                Write-Error "Failed to collect Infrastructure inventory: $($_.Exception.Message)"
                $infraInventory = @{
                    clusters = @(); datastores = @(); networks = @(); virtual_switches = @()
                    resource_pools = @(); folders = @(); datacenters = @(); distributed_switches = @()
                    port_groups = @(); vcenter_info = @{}
                }
            }

            # Extract vCenter instance name for use in filenames
            $vcenterInstanceName = "unknown"
            if ($infraInventory.vcenter_info -and $infraInventory.vcenter_info.full_name) {
                # Sanitize the vCenter full name for use in filenames
                $vcenterInstanceName = $infraInventory.vcenter_info.full_name -replace '[\\/:*?"<>|]', '_' -replace '\s+', '_'
                $vcenterInstanceName = $vcenterInstanceName.ToLower()
            }

            # Collect Host Inventory (ESXi hosts second)
            try {
                Write-ColorOutput "Gathering ESXi Host inventory..." -ForegroundColor Yellow
                $hostInventory = Get-HostInventoryData

                if ($hostInventory.Count -gt 0) {
                    # OPTIMIZATION: Batch file writes using runspaces or sequential with minimal overhead
                    foreach ($vmHost in $hostInventory) {
                        try {
                            $uuid = $vmHost.UUID
                            if ([string]::IsNullOrEmpty($uuid)) {
                                Write-Warning "Skipping Host with empty UUID: $($vmHost.Name)"
                                continue
                            }

                            $hostPath = Join-Path $outputDir "vcenter-$($uuid.ToLower())_${serverIdentifier}_${vcenterInstanceName}__host_info-${timestamp}.json"
                            # OPTIMIZATION: Use direct JSON conversion and file write
                            [System.IO.File]::WriteAllText($hostPath, ($vmHost | ConvertTo-Json -Depth 5 -Compress), [System.Text.Encoding]::UTF8)
                        }
                        catch {
                            Write-Warning "Failed to export Host '$($vmHost.Name)': $($_.Exception.Message)"
                        }
                    }
                    Write-ColorOutput "Host inventories exported: $($hostInventory.Count) files" -ForegroundColor Green
                } else {
                    Write-Warning "No ESXi Hosts found in vCenter"
                }
            }
            catch {
                Write-Error "Failed to collect Host inventory: $($_.Exception.Message)"
                $hostInventory = @()
            }

            # Collect VM Inventory (Virtual Machines last)
            try {
                Write-ColorOutput "Gathering Virtual Machine inventory..." -ForegroundColor Yellow
                $vmInventory = Get-VMInventoryData -ServerName $currentServer

                if ($vmInventory.Count -gt 0) {
                    # OPTIMIZATION: Batch file writes
                    foreach ($vm in $vmInventory) {
                        try {
                            $uuid = $vm.UUID
                            if ([string]::IsNullOrEmpty($uuid)) {
                                Write-Warning "Skipping VM with empty UUID: $($vm.Name)"
                                continue
                            }

                            $vmPath = Join-Path $outputDir "vcenter-$($uuid.ToLower())_${serverIdentifier}_${vcenterInstanceName}__vm_info-${timestamp}.json"
                            # OPTIMIZATION: Use direct JSON conversion and file write
                            [System.IO.File]::WriteAllText($vmPath, ($vm | ConvertTo-Json -Depth 5 -Compress), [System.Text.Encoding]::UTF8)
                        }
                        catch {
                            Write-Warning "Failed to export VM '$($vm.Name)': $($_.Exception.Message)"
                        }
                    }
                    Write-ColorOutput "VM inventories exported: $($vmInventory.Count) files" -ForegroundColor Green
                } else {
                    Write-Warning "No VMs found in vCenter"
                }
            }
            catch {
                Write-Error "Failed to collect VM inventory: $($_.Exception.Message)"
                $vmInventory = @()
            }

            # Save complete infrastructure as one file
            $infraPath = Join-Path $outputDir "vcenter-${hostUuid}_${serverIdentifier}_${vcenterInstanceName}__infra_info-${timestamp}.json"
            [System.IO.File]::WriteAllText($infraPath, ($infraInventory | ConvertTo-Json -Depth 6 -Compress), [System.Text.Encoding]::UTF8)
            Write-ColorOutput "Infrastructure inventory exported: $infraPath" -ForegroundColor Green

            # Save individual infrastructure components as separate files for easier analysis
            if ($infraInventory.clusters.Count -gt 0) {
                $clustersPath = Join-Path $outputDir "vcenter-${hostUuid}_${serverIdentifier}_${vcenterInstanceName}__cluster_info-${timestamp}.json"
                [System.IO.File]::WriteAllText($clustersPath, ($infraInventory.clusters | ConvertTo-Json -Depth 4 -Compress), [System.Text.Encoding]::UTF8)
                Write-ColorOutput "Clusters inventory exported: $clustersPath" -ForegroundColor Green
            }

            if ($infraInventory.datastores.Count -gt 0) {
                $datastoresPath = Join-Path $outputDir "vcenter-${hostUuid}_${serverIdentifier}_${vcenterInstanceName}__datastore_info-${timestamp}.json"
                [System.IO.File]::WriteAllText($datastoresPath, ($infraInventory.datastores | ConvertTo-Json -Depth 4 -Compress), [System.Text.Encoding]::UTF8)
                Write-ColorOutput "Datastores inventory exported: $datastoresPath" -ForegroundColor Green
            }

            if ($infraInventory.networks.Count -gt 0) {
                $networksPath = Join-Path $outputDir "vcenter-${hostUuid}_${serverIdentifier}_${vcenterInstanceName}__network_info-${timestamp}.json"
                [System.IO.File]::WriteAllText($networksPath, ($infraInventory.networks | ConvertTo-Json -Depth 4 -Compress), [System.Text.Encoding]::UTF8)
                Write-ColorOutput "Networks inventory exported: $networksPath" -ForegroundColor Green
            }

            if ($infraInventory.distributed_switches.Count -gt 0) {
                $vdsPath = Join-Path $outputDir "vcenter-${hostUuid}_${serverIdentifier}_${vcenterInstanceName}__vd_switch_info-${timestamp}.json"
                [System.IO.File]::WriteAllText($vdsPath, ($infraInventory.distributed_switches | ConvertTo-Json -Depth 4 -Compress), [System.Text.Encoding]::UTF8)
                Write-ColorOutput "Distributed Switches inventory exported: $vdsPath" -ForegroundColor Green
            }

            if ($infraInventory.port_groups.Count -gt 0) {
                $portGroupsPath = Join-Path $outputDir "vcenter-${hostUuid}_${serverIdentifier}_${vcenterInstanceName}__port_group_info-${timestamp}.json"
                [System.IO.File]::WriteAllText($portGroupsPath, ($infraInventory.port_groups | ConvertTo-Json -Depth 4 -Compress), [System.Text.Encoding]::UTF8)
                Write-ColorOutput "Port Groups inventory exported: $portGroupsPath" -ForegroundColor Green
            }

            if ($infraInventory.datacenters.Count -gt 0) {
                $datacentersPath = Join-Path $outputDir "vcenter-${hostUuid}_${serverIdentifier}_${vcenterInstanceName}__datacenter_info-${timestamp}.json"
                [System.IO.File]::WriteAllText($datacentersPath, ($infraInventory.datacenters | ConvertTo-Json -Depth 4 -Compress), [System.Text.Encoding]::UTF8)
                Write-ColorOutput "Datacenters inventory exported: $datacentersPath" -ForegroundColor Green
            }

            if ($infraInventory.vcenter_info.name) {
                $vCenterPath = Join-Path $outputDir "vcenter-${hostUuid}_${serverIdentifier}_${vcenterInstanceName}__vcenter_info-${timestamp}.json"
                [System.IO.File]::WriteAllText($vCenterPath, ($infraInventory.vcenter_info | ConvertTo-Json -Depth 4 -Compress), [System.Text.Encoding]::UTF8)
                Write-ColorOutput "vCenter Server info exported: $vCenterPath" -ForegroundColor Green
            }

            $summary = @{
                collection_time   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                vcenter_server    = $currentServer
                vcenter_version   = $connection.Version
                vcenter_build     = $connection.Build
                total_vms         = $vmInventory.Count
                total_hosts       = $hostInventory.Count
                total_clusters    = $infraInventory.clusters.Count
                total_datastores  = $infraInventory.datastores.Count
                total_datacenters = $infraInventory.datacenters.Count
                total_networks    = $infraInventory.networks.Count
                total_virtual_switches = $infraInventory.virtual_switches.Count
                total_distributed_switches = $infraInventory.distributed_switches.Count
                total_port_groups  = $infraInventory.port_groups.Count
                total_resource_pools = $infraInventory.resource_pools.Count
                total_folders     = $infraInventory.folders.Count
                collection_status = @{
                    vms_collected = if ($vmInventory.Count -gt 0) { "Success" } else { "No VMs found" }
                    hosts_collected = if ($hostInventory.Count -gt 0) { "Success" } else { "No Hosts found" }
                    infrastructure_collected = if ($infraInventory) { "Success" } else { "Failed" }
                }
            }

            $summaryPath = Join-Path $outputDir "vcenter-${hostUuid}_${serverIdentifier}_${vcenterInstanceName}__report-${timestamp}.json"
            [System.IO.File]::WriteAllText($summaryPath, ($summary | ConvertTo-Json -Depth 3), [System.Text.Encoding]::UTF8)
            Write-ColorOutput "Summary report exported: $summaryPath" -ForegroundColor Green

            # Update overall summary
            $overallSummary.total_vms_all_servers += $vmInventory.Count
            $overallSummary.total_hosts_all_servers += $hostInventory.Count
            $overallSummary.successful_servers += @{
                server_name = $currentServer
                vms_count = $vmInventory.Count
                hosts_count = $hostInventory.Count
                collection_time = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }

            Write-ColorOutput "vCenter inventory collection completed successfully for $currentServer!" -ForegroundColor Green
            Write-ColorOutput "Total VMs processed: $($vmInventory.Count)" -ForegroundColor White
            Write-ColorOutput "Total Hosts processed: $($hostInventory.Count)" -ForegroundColor White
            Write-ColorOutput "All inventory files saved to: $outputDir" -ForegroundColor White

            # Disconnect from current vCenter before processing next one
            if ($Global:DefaultVIServers.Count -gt 0) {
                Write-ColorOutput "Disconnecting from $currentServer..." -ForegroundColor Yellow
                Disconnect-VIServer -Server $currentServer -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to process vCenter Server '$currentServer': $($_.Exception.Message)"
            $overallSummary.failed_servers += @{
                server_name = $currentServer
                error_message = $_.Exception.Message
                collection_time = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }

            # Ensure we disconnect even on error
            if ($Global:DefaultVIServers.Count -gt 0) {
                Write-ColorOutput "Disconnecting from $currentServer due to error..." -ForegroundColor Yellow
                Disconnect-VIServer -Server $currentServer -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
    }

    # Create overall summary report
    $overallSummary.collection_end_time = Get-Date
    $overallSummary.total_duration_minutes = [math]::Round(($overallSummary.collection_end_time - $overallSummary.collection_start_time).TotalMinutes, 2)

    $overallSummaryPath = Join-Path $OutputFolderPath "vcenter_collection_overall_summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    [System.IO.File]::WriteAllText($overallSummaryPath, ($overallSummary | ConvertTo-Json -Depth 4), [System.Text.Encoding]::UTF8)
    Write-ColorOutput "Overall summary report exported: $overallSummaryPath" -ForegroundColor Green

    Write-ColorOutput "=== OVERALL COLLECTION SUMMARY ===" -ForegroundColor Cyan
    Write-ColorOutput "Total servers processed: $($overallSummary.total_servers_processed)" -ForegroundColor White
    Write-ColorOutput "Successful servers: $($overallSummary.successful_servers.Count)" -ForegroundColor Green
    Write-ColorOutput "Failed servers: $($overallSummary.failed_servers.Count)" -ForegroundColor Red
    Write-ColorOutput "Total VMs across all servers: $($overallSummary.total_vms_all_servers)" -ForegroundColor White
    Write-ColorOutput "Total Hosts across all servers: $($overallSummary.total_hosts_all_servers)" -ForegroundColor White
    Write-ColorOutput "Total duration: $($overallSummary.total_duration_minutes) minutes" -ForegroundColor White
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-ColorOutput "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
finally {
    if ($Global:DefaultVIServers.Count -gt 0) {
        Write-ColorOutput "Disconnecting from vCenter..." -ForegroundColor Yellow
        Disconnect-VIServer -Server * -Confirm:$false -ErrorAction SilentlyContinue
        Write-ColorOutput "Disconnected from vCenter" -ForegroundColor Green
    }
    Write-ColorOutput "Script execution completed." -ForegroundColor Cyan
}
