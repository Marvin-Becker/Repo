$Result = @()
$Result += "Microsoft Defender Antivirus Service: " + (Get-Service "Microsoft Defender Antivirus Service").Status
$AMRM = (Get-MpComputerStatus).AMRunningMode
$Result += "AMRunningMode: " + $AMRM
if ((Get-MpComputerStatus).AMServiceEnabled -eq $True) { $Result += "- AMServiceEnabled is True" } else { $Result += "- AMServiceEnabled is False" }
if ((Get-MpComputerStatus).AntispywareEnabled -eq $True) { $Result += "- AntispywareEnabled is True" } else { $Result += "- AntispywareEnabled is False" }
if ((Get-MpComputerStatus).AntivirusEnabled -eq $True) { $Result += "- AntivirusEnabled is True" } else { $Result += "- AntivirusEnabled is False" }
if ((Get-MpComputerStatus).RealTimeProtectionEnabled -eq $True) { $Result += "- RealTimeProtectionEnabled is True" } else { $Result += "- RealTimeProtectionEnabled is False" }
if ((Get-MpComputerStatus).BehaviorMonitorEnabled -eq $True) { $Result += "- BehaviorMonitorEnabled is True" } else { $Result += "- BehaviorMonitorEnabled is False" }
if ((Get-MpComputerStatus).IoavProtectionEnabled -eq $True) { $Result += "- IoavProtectionEnabled is True" } else { $Result += "- IoavProtectionEnabled is False" }
if ((Get-MpComputerStatus).OnAccessProtectionEnabled -eq $True) { $Result += "- OnAccessProtectionEnabled is True" } else { $Result += "- OnAccessProtectionEnabled is False" }

$AS = (Get-MpComputerStatus).AntispywareSignatureAge
$AV = (Get-MpComputerStatus).AntivirusSignatureAge
if ($AS -ge 3) { $Result += "- AntispywareSignatureAge is too old: $AS Days" } else { $Result += "- AntispywareSignatureAge is good: $AS Days" }
if ($AS -ge 3) { $Result += "- AntivirusSignatureAge is too old: $AV Days" } else { $Result += "- AntivirusSignatureAge is good: $AV Days" }

$Result

#Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Features' -name TamperProtection -value 0
#Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection' -name ForceDefenderPassiveMode -value 1
#Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection' -name ForceDefenderPassiveMode
#Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Features' -name TamperProtection
#Get-ItemPropertyValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -name DisableAntiSpyware

$ForceDefenderPassiveMode = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection' -Name ForceDefenderPassiveMode
if ($ForceDefenderPassiveMode) {
    Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection' -Name ForceDefenderPassiveMode
}

"Microsoft Defender Antivirus Service: " + (Get-Service "Microsoft Defender Antivirus Service").Status
"Windows Defender Antivirus Service: " + (Get-Service "Windows Defender Antivirus Service").Status
"Windows Defender Service: " + (Get-Service "Windows Defender Service").Status
#$DefenderRegistry = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'

if ((Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender') -eq $False) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
}
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware -Value 1
gpupdate /force

$DisableAntiSpyware = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware
$DisableAntiSpyware

$Service = Get-Service | Where-Object { ($_.Name -like "WinDefend") -OR ($_.Name -like "MsMpSvc") }
$Status = $Service.status
"Defender Service: " + $Status
"AMRunningMode: " + (Get-MpComputerStatus).AMRunningMode
"AMServiceEnabled: " + (Get-MpComputerStatus).AMServiceEnabled
"AntispywareEnabled: " + (Get-MpComputerStatus).AntispywareEnabled
"AntivirusEnabled: " + (Get-MpComputerStatus).AntivirusEnabled
"RealTimeProtectionEnabled: " + (Get-MpComputerStatus).RealTimeProtectionEnabled
"BehaviorMonitorEnabled: " + (Get-MpComputerStatus).BehaviorMonitorEnabled
"IoavProtectionEnabled: " + (Get-MpComputerStatus).IoavProtectionEnabled
"OnAccessProtectionEnabled: " + (Get-MpComputerStatus).OnAccessProtectionEnabled

if ($Status -ne "Running") {
    try { 
        Start-Service $Service -ErrorAction Stop
    } catch {
        Restart-Service $Service 
    }
}

### SCCM ### DisableWindowsDefender
$Server = $env:COMPUTERNAME
$ForceDefenderPassiveMode = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection' -Name ForceDefenderPassiveMode
if ($ForceDefenderPassiveMode) {
    Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection' -Name ForceDefenderPassiveMode
}

if ((Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender') -eq $False) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
}
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware -Value 1
try { Invoke-GPUpdate -Force -ErrorAction Stop } catch { gpupdate /force }
$DisableAntiSpyware = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware
Start-Sleep -s 3
$Service = Get-Service | Where-Object { ($_.Name -like "WinDefend") -OR ($_.Name -like "MsMpSvc") }
$Status = $Service.status
Write-Host $Server";"$DisableAntiSpyware";"$Status

### Get-DefenderStatus
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
[string[]]$McAfee = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object -FilterScript { $_.GetValue("DisplayName") -like "McAfee*" } | ForEach-Object -Process { $_.GetValue("DisplayName") } | Sort-Object
if ($McAfee) {
    [string]$McAfee = $McAfee -join ','
} elseif (!$McAfee) {
    [string]$McAfee = "No McAfee"
}
$Result += $McAfee + ";"

return $Result