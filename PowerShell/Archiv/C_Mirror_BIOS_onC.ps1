#Power off Hibernation
	"powercfg.exe /h off" | cmd

# Get ID of both Disks
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

#$mirrordisk_nr = (get-disk | Where-Object {$_.partitionstyle -eq "MBR" -and $_.NumberOfPartitions -eq 0} | Select-Object Number).Number

# Get sizes of the Partitions of the old System-Disk
$system_size = ((Get-Partition -DiskNumber $systemdisk_nr | Where-Object {$_.IsSystem-eq ”True”} | Select-Object Size).size) / 1048576
# Identify the System-Partition of the old System-Disk
$system_part = (Get-Partition -DiskNumber $systemdisk_nr | Where-Object {$_.IsSystem-eq ”True”} | Select-Object PartitionNumber).PartitionNumber

	[array]$assign = @(
	"select disk $systemdisk_nr",
	"select part $system_part",
	"assign letter=S",
	"exit")
	$assign | diskpart

### bis hier OK

# S: = \device\harddisk0\partition1
# T: = \device\harddisk1\partition1

[array]$copyboot = @(
	"attrib S:\Boot\BCD -s -h -r",
	"bcdboot C:\Windows /s T: /F BIOS /v")
	$copyboot | cmd

# +++++ Clone Windows Boot Manager +++++
Write-Host "Clone Windows Boot Manager..." -ForegroundColor Yellow
("bcdedit /store s:\boot\BCD /copy {bootmgr} /d `"Windows Boot Manager Cloned`"" | cmd)[4] -match '{.*}'
$bootmgr_id = $Matches[0]
$bootmgr_id
# $bootmgr_id = "{e55c0689-8f01-11ec-b80f-00505601191a}"

[array]$changeboot = @(
"bcdedit /store s:\boot\BCD /set $bootmgr_id device partition=C:",
#"bcdedit /set $bootmgr_id device `"partition=\Device\HardDiskVolume3`"",
#"bcdedit /store s:\boot\BCD /bootsequence $bootmgr_id /addfirst",
#"bcdedit /store s:\boot\BCD /displayorder neuesWin /addfirst"
"bcdedit /enum all /v")
$changeboot | cmd


Write-Host "S:\boot\BCD /ENUM ALL /V" -ForegroundColor Yellow
"Bcdedit /store s:\boot\BCD /enum all /v" | cmd
Write-Host "C:\boot\BCD /ENUM ALL /V" -ForegroundColor Yellow
"Bcdedit /store c:\boot\BCD /enum all /v" | cmd

$RESUME = "{94e3bfa3-e66b-11eb-af2d-b23e6dd36b84}"
$OSLOADER = "{94e3bfa4-e66b-11eb-af2d-b23e6dd36b84}"
$Recovery_s = "{94e3bfa7-e66b-11eb-af2d-b23e6dd36b84}"
$DevOp_s = "{94e3bfa8-e66b-11eb-af2d-b23e6dd36b84}"

	"Bcdedit /store s:\boot\BCD /set $DevOp_s ramdisksdidevice partition=c:" | cmd
	"bcdedit /store s:\boot\BCD /set $Recovery_s device `"ramdisk=[c:]\Recovery\WindowsRE\Winre.wim,$DevOp_s`"" | cmd
	"bcdedit /store s:\boot\BCD /set $Recovery_s osdevice `"ramdisk=[c:]\Recovery\WindowsRE\Winre.wim,$DevOp_s`"" | cmd
	"Bcdedit /store s:\boot\BCD /set {memdiag} device partition=c:" | cmd
	"bcdedit /store s:\boot\BCD /set {bootmgr} device partition=c:" | cmd


	"bootsect.exe /nt60 All /force",
	"bootrec /fixmbr",
	"bootrec /fixboot",
	"bootrec /rebuildbcd",
#	"bcdboot C:\Windows /m $bootmgr_id" | cmd

	# Reimage the Windows Recovery Partition
	Write-Host "Reimage the Windows Recovery Partition..." -ForegroundColor Yellow
	[array]$movewinre = @(
		"Reagentc.exe /disable",
		"Robocopy.exe C:\Windows\System32\Recovery T:\Recovery\WindowsRE /copyall /dcopy:t",
		"Reagentc.exe /setreimage /path T:\Recovery\WindowsRE",
		"Reagentc.exe /enable")
		$movewinre | cmd

<#
# Delete old Windows Boot Entry
Write-Host "Find secondary Plex of Resume and Windows Boot Loader"
	"bcdedit /store t:\boot\BCD /enum RESUME /v" | cmd
	"bcdedit /store t:\boot\BCD /enum OSLOADER /v" | cmd
Write-Host "Delete old Windows Boot Entry"
	"Bcdedit /store t:\boot\BCD /delete $RESUME" | cmd
	"Bcdedit /store t:\boot\BCD /delete $OSLOADER" | cmd

	"Bcdedit /store s:\boot\BCD /delete $RESUME" | cmd
	"Bcdedit /store s:\boot\BCD /delete $OSLOADER" | cmd

# ("Bcdedit /store t:\boot\BCD /enum all /v" | cmd) -match '{.*}'

# "bcdedit /store t:\boot\BCD /set {bootmgr} device `"partition=\Device\HardDiskVolume0`"" | cmd
"bcdedit /store t:\boot\BCD /set {bootmgr} device `"partition=\Device\HardDiskVolume0`"" | cmd
"bcdedit /store t:\boot\BCD /set {memdiag} device `"partition=\Device\HardDiskVolume0`"" | cmd
#>

<#
### Create Boot Manager
"Bcdedit –createstore t:\temp\BCD" | cmd
"Bcdedit –store t:\boot\BCD –create {bootmgr} /d `"Boot Manager`"" | cmd
"Bcdedit –store t:\boot\BCD –set {bootmgr} device partition=e:" | cmd
"Bcdedit –store t:\boot\BCD –create /d “Windows Server” –application osloader" | cmd
"Bcdedit –import t:\boot\BCD" | cmd
#>

<#
	"Bcdedit /store t:\boot\BCD /set $DevOp ramdisksdidevice partition=t:" | cmd
	"Bcdedit /store t:\boot\BCD /set {memdiag} device partition=t:" | cmd
	"bcdedit /store t:\boot\BCD /set $WBL_Rec device `"ramdisk=[t:]\Recovery\WindowsRE\Winre.wim,$DevOp`"" | cmd
	"bcdedit /store t:\boot\BCD /set $WBL_Rec osdevice `"ramdisk=[t:]\Recovery\WindowsRE\Winre.wim,$DevOp`"" | cmd
	"bcdedit /store t:\boot\BCD /set {bootmgr} device partition=t:" | cmd
	"bcdedit /store t:\boot\BCD /delete $ResHib" | cmd
	"bcdedit /store t:\boot\BCD /delete $WBL_Serv" | cmd

	$DevOp_sec = "" # Secondary
	$WBL_Serv_sec = "" # Secondary
	$ResHib_sec = "" # Secondary
	"bcdedit /set $WBL_Serv_sec device partition=t:" | cmd
	"Bcdedit /set $DevOp ramdisksdidevice partition=t:" | cmd
	"Bcdedit /set {memdiag} device partition=t:" | cmd
	"bcdedit /set $WBL_Rec device `"ramdisk=[t:]\Recovery\WindowsRE\Winre.wim,$DevOp`"" | cmd
	"bcdedit /set $WBL_Rec osdevice `"ramdisk=[t:]\Recovery\WindowsRE\Winre.wim,$DevOp`"" | cmd
	"bcdedit /set {bootmgr} device partition=t:" | cmd
	"bcdedit /delete $ResHib" | cmd
	"bcdedit /delete $WBL_Serv" | cmd

("bcdedit /store t:\boot\BCD /copy {bootmgr} /d `"Windows Boot Manager Cloned`"" | cmd)[4] -match '{.*}'
$bootmgr_id = $Matches[0]
#$bootmgr_t = "{573d96de-575c-11ec-9110-00505681951b}"
#$bootmgr_s = "{f1fa8279-575f-11ec-9112-00505681951b}"
#>


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


#	"Del T:\Boot\BCD" | cmd
# "Rename T:\Boot\BCD2 BCD" | cmd

[array]$setactiveT = @(
"select disk $systemdisk_nr",
"select part $system_part",
"inactive",
"select disk $mirrordisk_nr",
"select part 1",
"active",
"exit")
$setactiveT | diskpart


Write-Host "Breaking Mirror..." -ForegroundColor Yellow
$systemdisk_nr = 0
	[array]$breakmirror = @(
	"select volume c",
	"break disk $systemdisk_nr nokeep",
	"exit")
	$breakmirror | diskpart

Start-Sleep -s 10

Write-Host "Restart Computer" -ForegroundColor Yellow
#Restart-Computer
#>
