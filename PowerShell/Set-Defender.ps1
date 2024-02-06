#$ErrorActionPreference = "SilentlyContinue"
$Result = ""
$DisableAntiSpyware = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware).DisableAntiSpyware
if ($DisableAntiSpyware) {
    Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware
    $Result += "Disable Key removed;"
    try { Invoke-GPUpdate -Force -ErrorAction Stop } catch { gpupdate /force | Out-Null }
} else {
    $Result += "Disable Not set;"
}

$ForceDefenderPassiveMode = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection' -Name ForceDefenderPassiveMode).ForceDefenderPassiveMode
if ($ForceDefenderPassiveMode) {
    Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection' -Name ForceDefenderPassiveMode
    $Result += "Passive Mode removed;"
} else {
    $Result += "Passive Mode Not set;"
}

$Service = Get-Service | Where-Object { ($_.Name -like "WinDefend") -OR ($_.Name -like "MsMpSvc") }
[string]$Status = $Service.status
if ($Status -eq "Running") { 
    $Result += "Service already running;" 
} elseif ($Status -eq "Stopped") {
    try { 
        Start-Service $Service -ErrorAction Stop
        $Result += "Service started;"
        $Service = Get-Service | Where-Object { ($_.Name -like "WinDefend") -OR ($_.Name -like "MsMpSvc") }
        [string]$Status = $Service.status
    } catch {
        Restart-Service $Service -ErrorAction Stop
        $Result += "Service restarted;"
        $Service = Get-Service | Where-Object { ($_.Name -like "WinDefend") -OR ($_.Name -like "MsMpSvc") }
        [string]$Status = $Service.status
    }
} elseif (-not $Status) {
    $Result += "No Service;"
}
$Result += $Status + ";"
Return $Result


# Detect McAfee
[string[]]$McAfee = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object -FilterScript { $_.GetValue("DisplayName") -like "McAfee*" } | ForEach-Object -Process { $_.GetValue("DisplayName") } | Sort-Object
if ($McAfee) {
    $Uninstall = "McAfeeEndpointProductRemoval_22.5.0.54.exe"
    $RemTool = (Get-ChildItem -Path "C:\temp" -Recurse | Where-Object Name -Like "$Uninstall").FullName
    if ($RemTool) {
        Write-Output "Starting to uninstall McAfee..."
        cmd /c $RemTool --accepteula --ENS --MA --ENABLEDEFENDER --NOREBOOT
    } elseif (Test-Path "\\tsclient\Z\Install") {
        Copy-Item "\\tsclient\Z\Install\McAfee\$Uninstall" -Destination "C:\temp\" -Force
        Write-Output "Starting to uninstall McAfee..."
        cmd /c C:\temp\$Uninstall --accepteula --ENS --MA --ENABLEDEFENDER --NOREBOOT
    } elseif (Test-Path "\\tsclient\H") {
        Copy-Item "\\tsclient\H\$Uninstall" -Destination "C:\temp\" -Force
        Write-Output "Starting to uninstall McAfee..."
        cmd /c C:\temp\$Uninstall --accepteula --ENS --MA --ENABLEDEFENDER --NOREBOOT
    } elseif (Test-Path "\\tsclient\V\Install") {
        Copy-Item "\\tsclient\V\Install\McAfee\$Uninstall" -Destination "C:\temp\" -Force
        Write-Output "Starting to uninstall McAfee..."
        cmd /c C:\temp\$Uninstall --accepteula --ENS --MA --ENABLEDEFENDER --NOREBOOT
    } else { 
        Write-Output "No Uninstall-Package found."
        Exit
    }
} elseif (!$McAfee) {
    Write-Output "No McAfee installed"
}

$OSName = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption 
($OSName | Select-String -Pattern 'Windows' -Context 0) -match "[0-9]{4}" > $NULL
$OSVersion = $Matches.Values

if ($OSVersion -le 2012) {
    # Copy and Install SCEP
    $Install = "scepinstall.exe"
    $SCEP = (Get-ChildItem -Path "C:\temp" -Recurse | Where-Object Name -Like "scepinstall.exe").FullName
    if ($SCEP) {
        Write-Output "Install SCEP..."
        Start-Process $SCEP /s
    } elseif (Test-Path "\\tsclient\Z\Install") {
        Copy-Item "\\tsclient\Z\Install\SCCM_2107_Client\Upgrade\SCCM_Client" -Destination "C:\temp\" -Force
        Write-Output "Starting to Install SCEP..."
        Start-Process C:\temp\SCCM_Client\$Install /s
    } elseif (Test-Path "\\tsclient\H") {
        Copy-Item "\\tsclient\H\SCCM_2107_Client\Upgrade\SCCM_Client" -Destination "C:\temp\" -Force
        Write-Output "Starting to Install SCEP..."
        Start-Process C:\temp\SCCM_Client\$Install /s
    } elseif (Test-Path "\\tsclient\V\Install") {
        Copy-Item "\\tsclient\V\Install\SCCM_2107_Client\Upgrade\SCCM_Client" -Destination "C:\temp\" -Force
        Write-Output "Starting to Install SCEP..."
        Start-Process C:\temp\SCCM_Client\$Install /s
    }
}