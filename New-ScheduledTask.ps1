# Creating a scheduled task for the daily Postgres basebackup
# Task details
$taskName = "PostgresBackup"
$description = "Triggers Basebackup of Postgres RIS DB"
$runningUser = "Local Service"
$execute = "pwsh.exe"
$command = 'Import-Module medavis.postgresbackup -Force -ErrorAction Stop; Start-PostgresBackup'
$argument = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -Command `"$command`""

# Task creation
$trigger = New-ScheduledTaskTrigger -Daily -At '01:00AM'
$action = New-ScheduledTaskAction -Execute $execute -Argument $argument
$principal = New-ScheduledTaskPrincipal -UserId $runningUser -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)
Register-ScheduledTask $taskName -Action $action -Description $description -Principal $principal -Trigger $trigger -Settings $settings
