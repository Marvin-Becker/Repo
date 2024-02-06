#Power off Hibernation
	"powercfg.exe /h off" | cmd

# Get ID of both Disks
$systemdisk_nr = (get-disk | Where-Object {$_.isboot -eq "True"} | Select-Object Number).Number
$mirrordisk_nr = (get-disk | Where-Object {$_.partitionstyle -eq "RAW"} | Select-Object Number).Number

# Clean and convert Mirror-Disk to GPT
Write-Host "Clean and convert Mirror-Disk to GPT..." -ForegroundColor Yellow
	[array]$convert = @(
	"select disk $mirrordisk_nr",
	"clean",
	"online disk",
	"attributes disk clear readonly",
	"Convert GPT",
  "select part 1",
  "Delete partition override",
	"exit")
	$convert | diskpart


# Get sizes of the Partitions of the old System-Disk
$recovery_size = ((Get-Partition -DiskNumber $systemdisk_nr | Where-Object {$_.GPTType -eq ”{de94bba4-06d1-4d40-a16a-bfd50179d6ac}”} | Select-Object Size).size) / 1048576
$reserved_size = ((Get-Partition -DiskNumber $systemdisk_nr | Where-Object {$_.GPTType -eq ”{e3c9e316-0b5c-4db8-817d-f92df00215ae}”} | Select-Object Size).size) / 1048576
$system_size = ((Get-Partition -DiskNumber $systemdisk_nr | Where-Object {$_.GPTType -eq ”{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}”} | Select-Object Size).size) / 1048576
# Identify the System(EFI)-Partition System-Disk
$system_part = (Get-Partition -DiskNumber $systemdisk_nr | Where-Object {$_.GPTType -eq ”{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}”} | Select-Object PartitionNumber).PartitionNumber

	[array]$assign = @(
	"select disk $systemdisk_nr",
	"select part $system_part",
	"assign letter=P",
	"exit")
	$assign | diskpart

# Create new Partitions on the Mirror-Disk using the Size-Variables
Write-Host "Create new Partitions on the Mirror-Disk..." -ForegroundColor Yellow
	[array]$create = @(
	"select disk $mirrordisk_nr",
	"Create partition primary size=$recovery_size",
	"format quick fs=ntfs label='WinRE'",
	"set id='de94bba4-06d1-4d40-a16a-bfd50179d6ac'",
	"select disk $mirrordisk_nr",
	"create partition efi size=$system_size",
	"assign letter=S",
	"format fs=FAT32 quick",
	"select disk $mirrordisk_nr",
	"create partition msr size=$reserved_size",
	"list part",
	"exit")
	$create | diskpart


# Convert both Disks to dynamic
Write-Host "Convert both Disks to dynamic..." -ForegroundColor Yellow
	[array]$convdyn = @(
	"Select disk $systemdisk_nr",
	"Convert dynamic",
	"Select disk $mirrordisk_nr",
	"Convert dynamic",
	"exit")
	$convdyn | diskpart

# !!! Nach dem Konvertieren on DYN ist per PS nicht mehr auf die Disks bzw. die Partiotionen zuzugreifen

# Start Mirroring the C: Drive to Mirror-Disk
Write-Host "Start Mirroring the C: Drive to Mirror-Disk..." -ForegroundColor Yellow
	[array]$adddisk = @(
	"select volume c",
	"add disk=$mirrordisk_nr",
	"exit")
	$adddisk | diskpart

# Check if the Mirroring-Process is done:
Write-Host "Check if the Mirroring-Process is done..." -ForegroundColor Yellow
do{
    $mirrorstatus = ("for /f `"tokens=9 delims= `" %a IN ('echo list volume ^| diskpart ^| find `"Boot`"') do echo %a") | cmd
    Write-Host "Mirroring in process..." -ForegroundColor Yellow
    Start-Sleep -s 60
}
until ($mirrorstatus -eq "Healthy")
Write-Host "Mirroring done!" -ForegroundColor Green
Start-Sleep -s 10


# Clone Windows Boot Manager
Write-Host "Clone Windows Boot Manager..." -ForegroundColor Yellow
("bcdedit /copy {bootmgr} /d `"Windows Boot Manager Cloned`"" | cmd)[4] -match '{.*}'
$bootmgr_id = $Matches[0]

	[array]$changeboot = @(
	"bcdedit /set $bootmgr_id device partition=S:",
	"bcdedit /bootsequence {current} /addlast",
	"bcdedit /enum")
	$changeboot | cmd

	[array]$cloneboot = @("P:",
	"bcdedit /export P:\EFI\Microsoft\Boot\BCD2",
	"robocopy P:\ S:\ /e /r:0",
	"Rename S:\EFI\Microsoft\Boot\BCD2 BCD",
	"Del P:\EFI\Microsoft\Boot\BCD2")
	$cloneboot | cmd
Start-Sleep -s 10

Write-Host "Restart Computer" -ForegroundColor Yellow
#Restart-Computer
