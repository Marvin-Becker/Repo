<#
.SYNOPSIS
    Test-OpenPort is an advanced Powershell function to scan tcp ports and return results that can be forwarded to network teams
.DESCRIPTION
    Uses Test-NetConnection. Define multiple targets and multiple ports.
    Currently it can handle the following defined port/target sets:
    AD = Active directory ports
    SWS = Streamworks server on port 9600
    CMK = CheckMK servers on port 443 and 6556
    DDS = Datendrehscheibe on port 443 and 22
    SSL = Port 443
    McAfee = McAfee server und Ports. (ePo = 80,443; Repository = 8081)
.PARAMETER Target
    The target systems to test. Can be an array of strings.
.PARAMETER Port
    The port numbers to test. Can be an array of integers or a special keyword: AD, CMK, DDS, SSL, McAfee, or SWS.
.EXAMPLE
    Test-OpenPort -Target sid-500.com,cnn.com,10.0.0.1 -Port 80,443
    Tests Port 80 and 443 to Servers: sid-500.com, cnn.com ,10.0.0.1
.EXAMPLE
    Test-OpenPort sid-500.com,cnn.com,10.0.0.1 80 -Port 443
    Test Port 443 to the servers: sid-500.com, cnn.com, 10.0.0.1
.EXAMPLE
    Test-OpenPort -Port AD
    Test predefined AD Ports against all server set as DNS
.EXAMPLE
    Test-OpenPort -Port CMK
    Tests predefine CheckMK Ports against automatically resolved CheckMK servers
.EXAMPLE
    Test-OpenPort 10.0.1.1 -Port AD
    Tests predefined AD Prots againt the server 10.0.1.1
#>
function Test-OpenPort {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        $Target,
        [Parameter(Mandatory = $true, Helpmessage = 'Enter Port Numbers. Separate them by comma or enter AD, CMK, DDS, SSL, McAfee or SWS')]
        $Port
    )
    begin {
        $result = @()
        $PortsToTest = @()
        $TargetsToTest = @()
    }
    process {
        # Get all port that are to be tested
        foreach ($p in $Port) {
            switch ($p) {
                'AD' {
                    #Check if Parameter Port is empty if yes set to AD
                    if ($Null -eq $Target ) {
                        $Target = $p
                    }
                    #Domain Ports nach Thies (2016) = 42, 53, 88, 135, 136, 138, 139, 389, 443, 445, 464, 636, 1026, 1512, 3268, 3269
                    #Domain Ports nach Wiki (2021) = 53, 88, 135, 389, 445, 464, 636, 3268, 3269
                    $PortsToTest += 53, 88, 135, 139, 389, 445, 464, 636, 3268, 3269
                }
                'SWS' {
                    #Check if Parameter Port is empty if yes set to SWS
                    if ($Null -eq $Target ) {
                        $Target = $p
                    }
                    $PortsToTest += 9600
                }
                'SSL' {
                    $PortsToTest += 443
                }
                'CMK' {
                    if ($Null -eq $Target ) {
                        $Target = $p
                    }
                    $PortsToTest += 443, 6556
                }
                'DDS' {
                    if ($Null -eq $Target ) {
                        $Target = $p
                    }
                    $PortsToTest += 443, 22
                }
                'McAfee' {
                    if ($Null -eq $Target ) {
                        $Target = $p
                    }
                    $PortsToTest += 443, 80
                }
                { $_ -gt 1 -and $_ -lt 65535 } {
                    $PortsToTest += $p
                }
            }
        }
        #Test if $Target id empty
        if ($Null -eq $Target) {
            Write-Error "No Target to test. Please use -Target or -Port [AD, CMK, DDS, SSL, McAfee or SWS]."
        }
        # Get all targets that are to be tested
        foreach ($t in $Target) {
            switch ($t) {
                'AD' {
                    #Get AD Servers from Adapter with configured Default Gateway DNS Settings
                    $NetworkAdapterIPEnabled = (Get-CimInstance Win32_networkAdapterConfiguration | Where-Object { $_.IPEnabled })
                    $DialogIndex = ($NetworkAdapterIPEnabled | Where-Object { $null -ne $_.DefaultIPGateway }).InterfaceIndex
                    $DNS = (Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.InterfaceIndex -eq $DialogIndex })
                    foreach ($DnsServer in $DNS.DNSServerSearchOrder) {
                        $TargetsToTest += $DnsServer
                    }
                }
                'CMK' {
                    try {
                        $CheckMKRegistryPath = 'HKLM:\SOFTWARE\Arvato\OSConfig\CheckMK'
                        $CheckMkSiteServer = Get-ItemPropertyValue -Path $CheckMKRegistryPath -Name 'CheckMkSiteServer' -ErrorAction Stop
                        switch -Wildcard ($CheckMkSiteServer) {
                            '*gtloccmks*' {
                                $CheckMKServers = @(
                                    '145.228.114.201',
                                    '145.228.114.204'
                                )
                            }
                            '*egkcmksub*' { $CheckMKServers = '192.168.4.6' }
                            '*hetcmksub*' { $CheckMKServers = '10.16.61.101' }
                            '*ogecmksub*' { $CheckMKServers = '10.27.43.199' }
                            '*otgcmksub*' { $CheckMKServers = '10.180.4.177' }
                            '*stecmksub*' { $CheckMKServers = '10.175.4.10' }
                            '*swbcmksub*' { $CheckMKServers = '10.6.237.75' }
                            '*tntcmksub*' { $CheckMKServers = '172.26.55.205' }
                            default {
                                $CheckMKServers = @(
                                    '145.228.114.201',
                                    '145.228.114.204'
                                )
                            }
                        }
                        foreach ($CheckMKServer in $CheckMKServers) {
                            $TargetsToTest += $CheckMKServer
                        }
                    } catch {
                        Write-Verbose "Could not get CheckMKSiteServer from Registry"
                    }
                }
                'DDS' {
                    # Datendrehscheibe Admin und Office PSA
                    $TargetsToTest += 'fes-a.server.arvato-systems.de'
                    $TargetsToTest += 'fes-o.server.arvato-systems.de'
                }
                'SWS' {
                    #SWS Round Robin DNS
                    $TargetsToTest += "sw-ps-prod.server.arvato-systems.de"
                }
                'McAfee' {
                    try {
                        $RegTaniumClient = 'HKLM:\SOFTWARE\WOW6432Node\Tanium\Tanium Client\'
                        $MP = [string](Get-ItemProperty $RegTaniumClient -Name LastGoodServerName).LastGoodServerName
                        Switch -Wildcard ($MP) {
                            "*145.228.114.81*" { $McAfeeServer = "145.228.110.5" }
                            "*145.228.114.80*" { $McAfeeServer = "145.228.110.5" }
                            "*10.175.4.7*" { $McAfeeServer = "10.175.4.14"; $PortsToTest = @(8081) }
                            "*10.180.4.198*" { $McAfeeServer = "10.180.4.191"; $PortsToTest = @(8081) }
                            "*172.26.55.208*" { $McAfeeServer = "172.26.55.209"; $PortsToTest = @(8081) }
                            "*10.16.61.4*" { $McAfeeServer = "10.16.61.104"; $PortsToTest = @(8081) }
                            "*10.6.234.85*" { $McAfeeServer = "10.6.234.91"; $PortsToTest = @(8081) }
                            "*192.168.4.16*" { $McAfeeServer = "192.168.4.5"; $PortsToTest = @(8081) }
                            default { $McAfeeServer = "145.228.110.5" }
                        }
                    } catch {
                        $McAfeeServer = "145.228.110.5"
                    }
                    $TargetsToTest += $McAfeeServer
                }
                default {
                    $TargetsToTest += $t
                }
            }
        }
        foreach ($t in $TargetsToTest) {
            foreach ($p in $PortsToTest) {
                $connect = Test-NetConnection -ComputerName $t -Port $p -InformationLevel Detailed -WarningAction SilentlyContinue
                $result += [PSCustomObject]@{
                    'Source IP'    = $connect.SourceAddress;
                    'Target IP'    = $connect.RemoteAddress;
                    'Port'         = $connect.RemotePort;
                    'Gateway'      = $connect.NetRoute.NextHop
                    'Status'       = $connect.tcpTestSucceeded
                    'Time of Test' = Get-Date -Format HH:mm:ss
                }
            }
        }
    }
    end {
        return $result
    }
}