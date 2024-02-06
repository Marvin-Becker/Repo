[boolean]$PortUsed = $False
# Port 8081
try {
    $Connection8081 = Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue | Select-Object -First 1
    $ListenProcessID8081 = ($Connection8081).OwningProcess
    $ListenProcessName8081 = Get-Process -Id $ListenProcessID8081
    $ListenProcessProduct8081 = ($ListenProcessName8081).Product
    Write-Output "Port 8081 TCP is in use;$ListenProcessProduct8081;"
    if ($ListenProcessProduct8081 -notlike "McAfee*") {
        $PortUsed = $True
    }
} catch {
    Write-Output "No Process on Port 8081 TCP;No Software on Port 8081 TCP;"
}
# Port 8082
try {
    $Connection8082 = Get-NetUDPEndpoint -LocalPort 8082 -ErrorAction SilentlyContinue | Select-Object -First 1
    $ListenProcessID8082 = ($Connection8082).OwningProcess
    $ListenProcessName8082 = Get-Process -Id $ListenProcessID8082
    $ListenProcessProduct8082 = ($ListenProcessName8082).Product
    Write-Output "Port 8082 is in use;$ListenProcessProduct8082;"
    if ($ListenProcessProduct8082 -notlike "McAfee*") {
        $PortUsed = $True
    }
} catch {
    Write-Output "No Process on Port 8082 UDP;No Software on Port 8082 UDP;"
}


if ($PortUsed -eq $True) {
    Exit
}

$DenyMcAfee = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM' -Name DenyMcAfeeInstall
if ($DenyMcAfee) {
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM' -Name DenyMcAfeeInstall
    Write-Output "DenyMcAfee removed"
} else { Write-Output "DenyMcAfee Not set" }

$ForceDefenderPassiveMode = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection' -Name ForceDefenderPassiveMode
if ($ForceDefenderPassiveMode) {
    Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection' -Name ForceDefenderPassiveMode
    Write-Output "Passive Mode removed"
} else { Write-Output "Passive Mode Not set" }

$DisableAntiSpyware = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware
if ($DisableAntiSpyware -eq 1) {
    Write-Output "Disable Key already there"
} elseif ($DisableAntiSpyware -eq 0) {
    Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware -Value 1
    Write-Output "Disable Key set"
    try { Invoke-GPUpdate -Force -ErrorAction Stop } catch { gpupdate /force }
} elseif (-not $DisableAntiSpyware) {
    if ((Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender') -eq $False) {
        New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
    }
    Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware -Value 1
    Write-Output "Disable Key set"
    try { Invoke-GPUpdate -Force -ErrorAction Stop } catch { gpupdate /force }
}

### Copy and Install McAfee
$Install = "FramePkg.exe"
$McAfee = (Get-ChildItem -Path "C:\temp" -Recurse | Where-Object Name -Like "$Install").FullName
if ($McAfee) {
    Write-Output "Starting to install McAfee..."
    cmd /c $McAfee /install=agent /s
} elseif (Test-Path "\\tsclient\Z\Install") {
    Copy-Item "\\tsclient\Z\Install\McAfee\$Install" -Destination "C:\temp\" -Force
    Write-Output "Starting to install McAfee..."
    cmd /c C:\temp\$Install /install=agent /s
} elseif (Test-Path "\\tsclient\H") {
    Copy-Item "\\tsclient\H\$Install" -Destination "C:\temp\" -Force
    Write-Output "Starting to install McAfee..."
    cmd /c C:\temp\$Install /install=agent /s
} elseif (Test-Path "\\tsclient\V\Install") {
    Copy-Item "\\tsclient\V\Install\McAfee\$Install" -Destination "C:\temp\" -Force
    Write-Output "Starting to install McAfee..."
    cmd /c C:\temp\$Install /install=agent /s
} else { 
    Write-Output "No Install-Package found."
    Exit
}