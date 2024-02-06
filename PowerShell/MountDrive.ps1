New-Item -Type File -Path "C:\Windows\System32\GroupPolicy\Machine\Scripts\Startup\share.ps1" -Force
New-Item -Type File -Path "C:\Windows\System32\GroupPolicy\Machine\Scripts\Startup\share.bat" -Force
Start-process "C:\Windows\System32\GroupPolicy\Machine\Scripts\Startup"

$description = "IM103510244"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File `"C:\Windows\System32\GroupPolicy\Machine\Scripts\Startup\share.ps1`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)
Register-ScheduledTask azure_share_mount -Action $action -Description $description -Principal $principal -Trigger $trigger -Settings $settings

<#
Share for production:
lamifsprodstrgprdapp.file.core.windows.net\share
Please mount to:
exlamwvz13442 / IP 10.21.228.197
exlamwvl13454 / IP 10.21.228.134
#>

$connectTestResult = Test-NetConnection -ComputerName lamifsprodstrgprdapp.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"lamifsprodstrgprdapp.file.core.windows.net`" /user:`"localhost\lamifsprodstrgprdapp`" /pass:`"moGP6RJLGlPi2YXwcQNpy7CVYJtdL+8Zv2K1KSGgSm6Xa7bqoWkGeCnPLZDKdhtTih5Xb8SFpFcsFZHZCCMGFw==`""
    # Mount the drive
    New-PSDrive -Name Y -PSProvider FileSystem -Root \\lamifsprodstrgprdapp.file.core.windows.net\share -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

net use Y: "\\lamifsprodstrgprdapp.file.core.windows.net\share" /user:localhost\lamifsprodstrgprdapp "moGP6RJLGlPi2YXwcQNpy7CVYJtdL+8Zv2K1KSGgSm6Xa7bqoWkGeCnPLZDKdhtTih5Xb8SFpFcsFZHZCCMGFw==" /persistent:yes
cmdkey /add:"lamifsprodstrgprdapp.file.core.windows.net" /user:"localhost\lamifsprodstrgprdapp" /pass:"moGP6RJLGlPi2YXwcQNpy7CVYJtdL+8Zv2K1KSGgSm6Xa7bqoWkGeCnPLZDKdhtTih5Xb8SFpFcsFZHZCCMGFw=="
###########################################################
<#
Share for Acceptance:
\\lamifsprodstrgaccapp.file.core.windows.net\share
Please mount to:
exlamwva13443 / IP 10.21.228.198
exlamwvk13453 / IP 10.21.228.133
#>

$connectTestResult = Test-NetConnection -ComputerName lamifsprodstrgaccapp.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"lamifsprodstrgaccapp.file.core.windows.net`" /user:`"localhost\lamifsprodstrgaccapp`" /pass:`"GE1M2r9RwiyDmBLWuu89HuxgYBMDFa8ZKpWmHZM55h54oWU2NT1dRIV+Rcblg5aftFrf+YfEczkC1OV4KceLBA==`""
    # Mount the drive
    New-PSDrive -Name Y -PSProvider FileSystem -Root \\lamifsprodstrgaccapp.file.core.windows.net\share -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

net use Y: "\\lamifsprodstrgaccapp.file.core.windows.net\share" /user:localhost\lamifsprodstrgaccapp "GE1M2r9RwiyDmBLWuu89HuxgYBMDFa8ZKpWmHZM55h54oWU2NT1dRIV+Rcblg5aftFrf+YfEczkC1OV4KceLBA==" /persistent:yes

#############################################################
<#
Share for Test:
\\lamifsprodstrgtstapp.file.core.windows.net\share
Please mount to:
exlamwvg13423 / IP 10.21.228.196
exlamwvj13452 / IP 10.21.228.132
#>

$connectTestResult = Test-NetConnection -ComputerName lamifsprodstrgtstapp.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"lamifsprodstrgtstapp.file.core.windows.net`" /user:`"localhost\lamifsprodstrgtstapp`" /pass:`"rYgXpEwVLgCEekYUObzq5PudcVFQoaodbXl29C6kguhlDyVO2C+BnM2FSj8VRFThY7x6SBW5f7m0/BMc5pV1JA==`""
    # Mount the drive
    New-PSDrive -Name Y -PSProvider FileSystem -Root \\lamifsprodstrgtstapp.file.core.windows.net\share -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

net use Y: "\\lamifsprodstrgtstapp.file.core.windows.net\share" /user:localhost\lamifsprodstrgtstapp "rYgXpEwVLgCEekYUObzq5PudcVFQoaodbXl29C6kguhlDyVO2C+BnM2FSj8VRFThY7x6SBW5f7m0/BMc5pV1JA==" /persistent:yes

################################
