#Power off Hibernation
	"powercfg.exe /h off" | cmd

# Get ID of both Disks
$systemdisk_nr = (get-disk | Where-Object {$_.isboot -eq "True"} | Select-Object Number).Number
$system_part = (Get-Partition -DiskNumber $systemdisk_nr | Where-Object {$_.IsSystem-eq ”True”} | Select-Object PartitionNumber).PartitionNumber

	[array]$assign = @(
	"select disk $systemdisk_nr",
	"select part $system_part",
	"assign letter=S",
	"exit")
	$assign | diskpart


"bcdboot C:\Windows /S C:" | cmd
"Rename S:\Boot\BCD BCD_old" | cmd
"bcdedit /createstore C:\boot\bcd.tmp" | cmd
"bcdedit /store C:\boot\bcd.tmp /create {bootmgr} /d `"Windows Boot Manager`"" | cmd
"bcdedit /import C:\boot\bcd.tmp" | cmd
"bcdedit /set {bootmgr} device partition=C:" | cmd
"bcdedit /timeout 10" | cmd
"del C:\boot\bcd.tmp" | cmd

("bcdedit /create /d `"Windows Server`" /application osloader" | cmd)[4] -match '{.*}'
$OSLOADER = $Matches[0]
# $OSLOADER = "{5b8224e4-8f33-11ec-b810-00505601191a}"
"bcdedit /default $OSLOADER" | cmd
"bcdedit /set {default} device partition=C:"| cmd
"bcdedit /set {default} osdevice partition=C:"| cmd
"bcdedit /set {default} path \Windows\system32\winload.exe"| cmd
"bcdedit /set {default} systemroot \Windows"| cmd
"bcdedit /displayorder {default} /addlast" | cmd

[array]$setactiveT = @(
"select disk $systemdisk_nr",
"select part $system_part",
"inactive",
"select disk $systemdisk_nr",
"select part 2",
"active",
"exit")
$setactiveT | diskpart

Start-Sleep -s 10

Write-Host "Restart Computer" -ForegroundColor Yellow
#Restart-Computer

$systemdisk_nr = (get-disk | Where-Object {$_.isboot -eq "True"} | Select-Object Number).Number
$mirrordisk_nr = (get-disk | Where-Object {$_.partitionstyle -eq "RAW"} | Select-Object Number).Number

# Clean and convert Mirror-Disk
Write-Host "Clean and convert Mirror-Disk..." -ForegroundColor Yellow
[array]$convert = @(
	"select disk $mirrordisk_nr",
	"online disk",
	"clean",
	"attributes disk clear readonly",
	"Convert MBR",
	"select part 1",
	"Delete partition override",
	"exit")
	$convert | diskpart

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
			$mirrorstatus = ("for /f `"tokens=8 delims= `" %a IN ('echo list volume ^| diskpart ^| find `"Boot`"') do echo %a") | cmd
			Write-Host "Mirroring in process..." -ForegroundColor Yellow
			Start-Sleep -s 60
		}
		until ($mirrorstatus -eq "Healthy")
		Write-Host "Mirroring done!" -ForegroundColor Green

		Start-Sleep -s 10

"bcdedit /displayorder {aeb6765a-8fd6-11ec-b812-00505601191a} /addfirst" | cmd
"bcdedit /default {aeb6765a-8fd6-11ec-b812-00505601191a}" | cmd

Write-Host "Restart Computer" -ForegroundColor Yellow
#Restart-Computer

# Create new Partitions on the Mirror-Disk using the Size-Variables
Write-Host "Create new Partitions on the Mirror-Disk..." -ForegroundColor Yellow
	[array]$create = @(
	"select disk 1",
#	"Create partition primary size=$system_size",
	"select part 1",
	"format fs=ntfs quick label='System Reserved'",
	"assign letter=T",
	"list part",
	"list volume",
	"exit")
	$create | diskpart




Write-Host "Breaking Mirror..." -ForegroundColor Yellow
$systemdisk_nr = 0
	[array]$breakmirror = @(
	"select volume c",
	"break disk $systemdisk_nr nokeep",
	"exit")
	$breakmirror | diskpart


#>
