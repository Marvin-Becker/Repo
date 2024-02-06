$TaskName = "Azure_Share_Mount"
$description = "IM103510244"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File `"C:\Windows\System32\GroupPolicy\Machine\Scripts\Startup\share.ps1`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)
Register-ScheduledTask $TaskName -Action $action -Description $description -Principal $principal -Trigger $trigger -Settings $settings

#########################

$TaskName = "Test"
$Description = "Test"
$RunningUser = "SYSTEM"
$FilePath = "C:\Temp\Test.ps1"

if($FilePath -like "*.ps1"){
    $Execute = "PowerShell.exe"
    $Argument = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File " + "`"" + $FilePath + "`""
} else {
    $Execute =  "`"" + $FilePath + "`""
}

$Trigger = New-ScheduledTaskTrigger -AtStartup
$Action = New-ScheduledTaskAction -Execute $Execute -Argument $Argument
$Principal = New-ScheduledTaskPrincipal -UserID $RunningUser -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)
Register-ScheduledTask $TaskName -Action $Action -Description $Description -Principal $Principal -Trigger $Trigger -Settings $Settings

### Boot-LUN
$TaskName = "Boot-LUN"
$Description = "Mirror the Boot-LUN"
$RunningUser = "SYSTEM"
$FilePath = "C:\SZIR\Mirror.ps1"
$Execute = "PowerShell.exe"
$Argument = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File " + "`"" + $FilePath + "`""

$Trigger = New-ScheduledTaskTrigger -Once -At "12/31/2022 10:00:00 PM"
$Action = New-ScheduledTaskAction -Execute $Execute -Argument $Argument
$Principal = New-ScheduledTaskPrincipal -UserID $RunningUser -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)
Register-ScheduledTask $TaskName -Action $Action -Description $Description -Principal $Principal -Trigger $Trigger -Settings $Settings
