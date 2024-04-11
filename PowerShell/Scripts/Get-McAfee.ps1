$Result = ""
[string]$Server = $env:COMPUTERNAME
$Result += $Server + ";"
[string]$Domain = (Get-CimInstance win32_computersystem).Domain
$Result += $Domain + ";"
[string[]]$DialogIP = (Get-NetIPAddress | Where-Object { (($_.InterfaceAlias -Like "Dialog*" -AND $_.AddressFamily -eq "IPv4")) -OR (($_.InterfaceAlias -Like "Ethernet*" -AND $_.AddressFamily -eq "IPv4")) } ).IPAddress
[string]$DialogIP = $DialogIP -join ','
$Result += $DialogIP + ";"
[string]$OSName = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
($OSName | Select-String -Pattern 'Windows' -Context 0) -match "[0-9]{4}" > $NULL
[string]$OSVersion = $Matches.Values
$Result += $OSVersion + ";"

### Get-DefenderStatus
[string]$DisableAntiSpyware = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware).DisableAntiSpyware
if (!$DisableAntiSpyware) {
    $DisableAntiSpyware = "Not set"
}
$Result += $DisableAntiSpyware + ";"
[string]$AntispywareEnabled = (Get-MpComputerStatus).AntispywareEnabled
if (!$AntispywareEnabled) {
    $AntispywareEnabled = "No MP Status"
}
$Result += $AntispywareEnabled + ";"
[string]$AMRunningMode = (Get-MpComputerStatus).AMRunningMode
if (!$AMRunningmode) {
    $AMRunningmode = "No Run-Mode Status"
}
$Result += $AMRunningMode + ";"
$Service = Get-Service | Where-Object { ($_.Name -like "WinDefend") -OR ($_.Name -like "MsMpSvc") }
[string]$Status = $Service.status
if (!$Status) {
    $Status = "No Service Status"
}
$Result += $Status + ";"
[string[]]$McAfee = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object -FilterScript { ($_.GetValue("DisplayName") -like "McAfee*") -OR ($_.GetValue("DisplayName") -like "Trellix*") } | ForEach-Object -Process { $_.GetValue("DisplayName") } | Sort-Object
if ($McAfee) {
    [string]$McAfee = $McAfee -join ','
} elseif (!$McAfee) {
    [string]$McAfee = "No McAfee"
}
$Result += $McAfee + ";"


### McAfee EPO Server Port Check
$MP = [string](Get-ItemProperty HKLM:\SOFTWARE\Microsoft\CCM\ -Name AllowedMPs).AllowedMPs
Switch -Wildcard ($MP) {
    "*gtlsccm2012*" { $TIP = "145.228.110.5" }
    "*gtstesccm0001*" { $TIP = "10.175.4.14" }
    "*gtotgsccm0001*" { $TIP = "10.180.4.191" }
    "*GTALFWVX03716*" { $TIP = "172.26.55.209" }
    "*GTLHETWVM0017*" { $TIP = "10.16.61.104" }
    "*GTLNMIWVM1470*" { $TIP = "10.6.234.85" }
    "*GTLEGKWVM0009*" { $TIP = "192.168.4.5" }
    default { $TIP = "145.228.110.5" }
}
$Result += $MP + ";"
$Result += $TIP + ";"
$Ports = @("443", "80")
$IPs = $TIP
foreach ($IP in $IPs) {
    foreach ($Port in $Ports) {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($IP, $Port)
        if ($tcpClient.Connected) {
            $Result += "Port $Port Connected;"
            $tcpClient.Close()
        } else {
            $Result += "Failed on $Port;"
        }
    }
}

### McAfee Agent Port Check
# Port 8081 TCP
try {
    Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue | Where-Object OwningProcess -NE 0 | ForEach-Object { [string[]]$ProcessIDs8081 += $_.OwningProcess } 
    if ($ProcessIDs8081) {
        $ProcessIDs8081 = $ProcessIDs8081 | Get-Unique
        foreach ($ID in $ProcessIDs8081) { [string[]]$ProcessProducts8081 += (Get-Process -Id $ID).Product }
        [string]$ProcessProducts8081 = $ProcessProducts8081 -join ','
        $Result += "Port 8081 TCP is in use;$ProcessProducts8081;"
    } else { $Result += "No Process on Port 8081 TCP;No Software on Port 8081 TCP;" }
} catch {
    $Result += "No Process on Port 8081 TCP;No Software on Port 8081 TCP;"
}
# Port 8082 UDP
try {
    $ProcessName8082 = ((netstat -anobv | Select-String -Pattern 'UDP(.*?)8082' -Context 1).Context.PostContext[1]) -replace '[ \[.exe\]]'
    $ProcessProduct8082 = (Get-Process $ProcessName8082).Product
    $Result += "Port 8082 is in use;$ProcessProduct8082;"
} catch {
    $Result += "No Process on Port 8082 UDP;No Software on Port 8082 UDP;"
}

Return $Result

<#
# Port 8081 TCP
try {
    $ProcessName8081 = ((netstat -anobv | Select-String -Pattern 'TCP(.*?)8081' -Context 1).Context.PostContext[1]) -replace '[ \[.exe\]]'
    $ProcessProduct8081 = (Get-Process $ProcessName8081).Product
    $Result += "Port 8081 TCP is in use;$ProcessProduct8081;"
} catch {
    $Result += "No Process on Port 8081 TCP;No Software on Port 8081 TCP;"
}
# Port 8082 UDP
try {
    $ProcessName8082 = ((netstat -anobv | Select-String -Pattern 'UDP(.*?)8082' -Context 1).Context.PostContext[1]) -replace '[ \[.exe\]]'
    $ProcessProduct8082 = (Get-Process $ProcessName8082).Product
    $Result += "Port 8082 is in use;$ProcessProduct8082;"
} catch {
    $Result += "No Process on Port 8082 UDP;No Software on Port 8082 UDP;"
}

Return $Result
#>

<#
# Port 8081 TCP
try {
    $Connection8081 = Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue | Select-Object -First 1
    $ProcessID8081 = ($Connection8081).OwningProcess
    $ProcessName8081 = Get-Process -Id $ProcessID8081
    $ProcessProduct8081 = ($ProcessName8081).Product
    $Result += "Port 8081 TCP is in use;$ProcessProduct8081;"
} catch {
    $Result += "No Process on Port 8081 TCP;No Software on Port 8081 TCP;"
}
# Port 8082 UDP
try {
    $Connection8082 = Get-NetUDPEndpoint -LocalPort 8082 -ErrorAction SilentlyContinue | Select-Object -First 1
    $ProcessID8082 = ($Connection8082).OwningProcess
    $ProcessName8082 = Get-Process -Id $ProcessID8082
    $ProcessProduct8082 = ($ProcessName8082).Product
    $Result += "Port 8082 is in use;$ProcessProduct8082;"
} catch {
    $Result += "No Process on Port 8082 UDP;No Software on Port 8082 UDP;"
}

Return $Result
#>