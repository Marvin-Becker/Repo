<#
.SYNOPSIS
Quick analyzation of the Streamworks agent on a server.

.DESCRIPTION
Checks the status of the service, the streamworks.conf and crucial network connections.
#>

<#
Author
Sebastian Moock | NMD-I2.1 | sebastian.moock@bertelsmann.de
#>


#region Prerequisites
    # Streamworks agent present
    $StreamworksService = Get-Service -Name 'StreamworksAgent_Prod_Md0100' -ErrorVariable ServiceError -ErrorAction SilentlyContinue

    if ($ServiceError -and ($ServiceError | foreach {$_.FullyQualifiedErrorId -like "*NoServiceFoundForGivenName*"})) {
        Return 'There is no Streamworks agent present on this server.'
    }

    # PowerShell version high enough
    if (((Get-Host).Version).Major -lt 5) {
        Return 'PowerShell version not sufficient'
    }

    # streamworks.conf ok?
    $StreamworksConf = 'C:\WORK\streamworks\prod\md0100\conf\streamworks.conf'
    $StreamworksConfStatus = ''

    try {
        Get-Item $StreamworksConf | Out-Null
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        $StreamworksConfStatus = 'could not be found.'
    }

    if ((Get-Item $StreamworksConf).Length -lt 500) {
        $StreamworksConfStatus = 'could be missing information'
    }
    else {
        $StreamworksConfStatus = 'probably ok'
    }
#endregion Prerequisites

#region Variables
    $Hostname = $env:COMPUTERNAME
    $NICIndex = (Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.NetConnectionID -like "*Dialog*" }).DeviceID
    $NICConfiguration = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object {$_.Index -eq $NICIndex}
    $DialogIP = (Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object {$_.Index -eq $NICIndex}).IPAddress
    $DIalogSubnetMask = $NICConfiguration.IPSubnet
    $DialogGateway = ((Get-NetIPConfiguration | Where-Object {$_.InterfaceAlias -eq 'Dialog'}).IPv4DefaultGateway).NextHop
    $DNSServers = (Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.InterfaceIndex -eq $NICConfiguration.InterfaceIndex }).DNSServerSearchOrder
    $StreamworksCluster = @(
        '145.228.56.69',
        '145.228.56.70',
        '145.228.56.71',
        '145.228.56.72'
    )
#endregion global variables

#region functions
    function Test-TCPConnection {
        param(
            [parameter(Mandatory = $true)]
            [String]$targetIPs,
            [parameter(Mandatory = $true)]
            [String]$targetPorts
        )
        foreach ($IP in $targetIPs.Split(",")) {
            foreach ($port in $targetPorts.Split(",")) {
                $TCPCon = New-Object Net.Sockets.TcpClient
                $ErrorActionPreference = 'SilentlyContinue'
                Write-Host "Checking connection to $IP : $port" -ForegroundColor Yellow
                $connect = $TCPCon.BeginConnect($ip, $port, $null, $null)
                $wait = $connect.AsyncWaitHandle.WaitOne(5000, $false)
                if (-not $wait) {
                    Write-Host 'Port is BLOCKED.' -ForegroundColor Red
                } else {
                    if ($TCPCon.Connected) {
                        Write-Host 'Port is OPEN.' -ForegroundColor Green
                        $TCPCon.EndConnect($connect) | out-Null
                    } else {
                        Write-Host 'Port is BLOCKED.' -ForegroundColor Red
                    }
                }
                $TCPCon.Dispose | Out-Null
                $TCPCon = $null | Out-Null
            }
        }
    }
#endregion

#region overview
    Write-Host ''
    Write-Host $Hostname
    Write-Host '-----------------------'
    Write-Host ''
    Write-Host 'Agent information'
    Write-Host '-----------------------'
    Write-Host 'Agent found:' $StreamworksService.Name
    Write-Host 'Current status:' $StreamworksService.Status
    Write-Host 'StartType:' $StreamworksService.StartType
    Write-Host 'streamworks.conf:' $StreamworksConfStatus
    Write-Host ''
    Write-Host 'Connection information'
    Write-Host '-----------------------'
    Write-Host 'IP address:' $DialogIP
    Write-Host 'Subnet:' $DIalogSubnetMask
    Write-Host 'Gateway:' $DialogGateway
    Write-Host 'DNS servers:' $DNSServers
    Write-Host 'Streamworks servers:' $StreamworksCluster
#endregion overview

#region operation
    # Trying to stop the Streamworks service by killing the process
    if ($StreamworksService.Status -eq 'Stopping') {
        Write-Host $StreamworksService "is in status" $StreamworksService.Status -ForegroundColor Red
        Write-Host 'Trying to kill the process' -ForegroundColor Cyan
        try {
            Stop-Process -Name $StreamworksProcess -Verbose
        }
        catch [Microsoft.PowerShell.Commands.StartServiceCommand],[Microsoft.PowerShell.Commands.SetServiceCommand] {
            Write-Host $StreamworksService.Name "could not be stopped." -ForegroundColor Red
        }
    }

    # Trying to start the Streamworks agent when its stopped and making sure the starttype is 'automatic'
    if ($StreamworksService.Status -eq 'Stopped') {
        Write-Host $StreamworksService "is in status" $StreamworksService.Status -ForegroundColor Red
        Write-Host 'Trying to start service' -ForegroundColor Cyan
        try {
            Start-Service $StreamworksService -Verbose
            Set-Service $StreamworksService -StartupType Automatic -Verbose
        }
        catch {
            Write-Host $StreamworksService.Name 'could not be started.' -ForegroundColor Red
        }
    }

    # Testing connection over port 53 to the domain controllers
    Write-Host ''
    Write-Host 'DNS connection'

    foreach ($Entry in $DNSServers) {
        Test-TCPConnection -targetIPs $Entry -targetPorts '53'
    }

    # Testing of open ports to the Streamworks cluster
    Write-Host ''
    Write-Host 'Streamworks cluster connection'

    foreach ($Entry in $StreamworksCluster) {
        Test-TCPConnection -targetIPs $Entry -targetPorts '9600'
    }
#endregion operation