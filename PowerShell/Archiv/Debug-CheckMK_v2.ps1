<#
.SYNOPSIS
Quick analyzation of the CheckMK agent on a server.

.DESCRIPTION
Checks the crucial network connections.
#>

<#
Author: Marvin Becker | NMD-I2.1 | Marvin.Becker@outlook.de
Last Update: 10.11.2022 - Marvin Krischker  | Marvin.Krischker@outlook.de
#>


#region Prerequisites
# Windows Firewall
$WindowsFireWallStandard = Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile' -Name EnableFirewall
$WindowsFireWallDomain = Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile' -Name EnableFirewall
$WindowsFireWallPublic = Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile' -Name EnableFirewall
$WindowsFirewallStatus = ''

if (($WindowsFireWallStandard -or $WindowsFireWallDomain -or $WindowsFireWallPublic) -eq 1) {
    $WindowsFirewallStatus = 'Enabled'
} else {
    $WindowsFirewallStatus = 'Disabled'
}
#endregion Prerequisites


#region Variables
$Hostname = $env:COMPUTERNAME
$NICIndex = (Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.NetConnectionID -like "*Dialog*" }).DeviceID
$NICConfiguration = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $NICIndex }
$DialogIP = (Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $NICIndex }).IPAddress
$DIalogSubnetMask = $NICConfiguration.IPSubnet
$DialogGateway = ((Get-NetIPConfiguration | Where-Object { $_.InterfaceAlias -eq 'Dialog' }).IPv4DefaultGateway).NextHop
$DNSServers = (Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.InterfaceIndex -eq $NICConfiguration.InterfaceIndex }).DNSServerSearchOrder

$Customer = Read-Host -Prompt "Which Customer? ASYS, EGK, HET, OGE, OTG, STE, SWB, TNT ?"
switch ($Customer) {
    'ASYS' {
        $CheckMKSevers = @(
            '145.228.114.201',
            '145.228.114.204'
        ) 
    }
    'EGK' { $CheckMKSevers = '192.168.4.6' }
    'HET' { $CheckMKSevers = '10.16.61.101' }
    'OGE' { $CheckMKSevers = '10.27.43.199' }
    'OTG' { $CheckMKSevers = '10.180.4.177' }
    'STE' { $CheckMKSevers = '10.175.4.10' }
    'SWB' { $CheckMKSevers = '10.6.237.75' }
    'TNT' { $CheckMKSevers = '172.26.55.205' }
    default {
        $CheckMKSevers = @(
            '145.228.114.201',
            '145.228.114.204'
        )
    }
}
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
                $Failed = $true
            } else {
                if ($TCPCon.Connected) {
                    Write-Host 'Port is OPEN.' -ForegroundColor Green
                    $TCPCon.EndConnect($connect) | Out-Null
                } else {
                    Write-Host 'Port is BLOCKED.' -ForegroundColor Red
                    $Failed = $true
                }
            }
            $TCPCon.Dispose | Out-Null
            $TCPCon = $null | Out-Null
        }
    }
}
#endregion


#region operation
Clear-Host
#endregion operation

#region overview
Write-Host ''
Write-Host $Hostname
Write-Host '-----------------------'
Write-Host ''
Write-Host 'Connection information'
Write-Host '-----------------------'
Write-Host 'IP address:' $DialogIP
Write-Host 'Subnet:' $DIalogSubnetMask
Write-Host 'Gateway:' $DialogGateway
Write-Host 'Windows Firewall:' $WindowsFirewallStatus
Write-Host 'DNS servers:' $DNSServers
Write-Host 'CheckMK servers:' $CheckMKSevers

# Testing connection over port 53 to the domain controllers
Write-Host ''
Write-Host 'DNS connection'

foreach ($Entry in $DNSServers) {
    Test-TCPConnection -targetIPs $Entry -targetPorts '53'
}

# Testing of open ports to the Streamworks cluster
Write-Host ''
Write-Host 'CheckMK connection'

foreach ($Entry in $CheckMKSevers) {
    Test-TCPConnection -targetIPs $Entry -targetPorts '443'
    Test-TCPConnection -targetIPs $Entry -targetPorts '6556'
}
#endregion overview

if ($Failed -ne $true) {
    Restart-Service CheckMkService -Verbose -Force
}