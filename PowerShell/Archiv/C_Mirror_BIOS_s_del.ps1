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

Write-Host "Start Mirroring the S: Drive to Mirror-Disk..." -ForegroundColor Yellow
[array]$adddisk_s = @(
	"select volume s",
	"add disk=$mirrordisk_nr",
	"exit")
	$adddisk_s | diskpart

# Start Mirroring the C: Drive to Mirror-Disk
Write-Host "Start Mirroring the C: Drive to Mirror-Disk..." -ForegroundColor Yellow
[array]$adddisk_c = @(
	"select volume c",
	"add disk=$mirrordisk_nr",
	"exit")
	$adddisk_c | diskpart

# Check if the Mirroring-Process is done:
Write-Host "Check if the Mirroring-Process is done..." -ForegroundColor Yellow
do{
	$mirrorstatus = ("for /f `"tokens=8 delims= `" %a IN ('echo list volume ^| diskpart ^| find `"Boot`"') do echo %a") | cmd
	Write-Host "Mirroring in process..." -ForegroundColor Yellow
	Start-Sleep -s 60
}
until ($mirrorstatus -eq "Healthy")
Write-Host "Mirroring done!" -ForegroundColor Green

<#
# Reimage the Windows Recovery Partition
Write-Host "Reimage the Windows Recovery Partition..." -ForegroundColor Yellow
[array]$movewinre = @(
	"Reagentc.exe /disable",
	"Reagentc.exe /setreimage /path S:\Recovery\WindowsRE",
	"Reagentc.exe /enable")
	$movewinre | cmd
#>

function GetIdentifier() {
param(
		[Parameter(Mandatory = $True)]
		[ValidateSet("Resume from Hibernate","Windows Memory Tester")]
		$pattern
)
		$id = $NULL
    bcdedit /enum all |
    Select-String -Pattern $pattern -context 2 |
    ForEach-Object {$id += ($_.Context.PostContext[1] -replace '^identifier +')}
        $id = $id.replace('}{','},{')
        $id = $id.split(',')[0]
        return $id
}

function GetIdentifierDevOps(){
    bcdedit /enum all |
    Select-String -Pattern 'Device options' -context 2 |
    ForEach-Object {$DevOps += ($_.Context.PostContext[1] -replace '^identifier +')}
    $DevOps = $DevOps.replace('}{','},{')
    $DevOps = $DevOps.split(',')[1]
    return $DevOps
}
$DevOps = GetIdentifierDevOps

$Bootmgr_new = (bcdedit /enum all |
    Select-String -Pattern 'Windows Boot Manager - secondary plex' -context 2 |
    ForEach-Object {($_.Context.PreContext[0] -replace '^identifier +')})
<#
$Recovery = (bcdedit /enum OSLOADER |
    Select-String -Pattern 'Windows Recovery Environment' -context 3 |
    ForEach-Object {($_.Context.PreContext[0] -replace '^identifier +')})
#>
$Windows_new = (bcdedit /enum OSLOADER |
    Select-String -Pattern '\w*secondary plex' -context 3 |
    ForEach-Object {($_.Context.PreContext[0] -replace '^identifier +') })


$Resume = GetIdentifier -pattern "Resume from Hibernate"

Write-Host "Delete old Entries..." -ForegroundColor Yellow
"bcdedit /delete $Bootmgr_new /f" |cmd
"bcdedit /delete $DevOps" | cmd
"bcdedit /delete $Resume" | cmd
"bcdedit /delete {current} /f" | cmd
"bcdedit /delete {memdiag} /f" | cmd

$DevOps_new = GetIdentifierDevOps
$Resume_new = GetIdentifier -pattern "Resume from Hibernate"
$Memdiag_new  = GetIdentifier -pattern "Windows Memory Tester"

Write-Host "Reorder the Boot Manager..." -ForegroundColor Yellow
"bcdedit /default $Windows_New"| cmd
"bcdedit /displayorder $Windows_New /addfirst" | cmd
"bcdedit /bootsequence $Windows_New" |cmd
#"bcdedit /set $Recovery device `"ramdisk=[s:]\Recovery\WindowsRE\Winre.wim,$DevOps_new`"" | cmd
#"bcdedit /set $Recovery osdevice `"ramdisk=[s:]\Recovery\WindowsRE\Winre.wim,$DevOps_new`"" | cmd
#"bcdedit /set {memdiag} device partition=s:" | cmd
#"bcdedit /set $DevOps ramdisksdidevice partition=s:" | cmd

Write-Host "Reset descriptions..." -ForegroundColor Yellow
#"bcdedit /set $Bootmgr_new description `"Windows Boot Manager`"" | cmd
"bcdedit /set $Windows_New description `"Windows Server`"" | cmd
"bcdedit /set $DevOps_new description `"Windows Recovery`"" | cmd
"bcdedit /set $Resume_new description `"Windows Resume Application`"" | cmd
"bcdedit /set $Memdiag_new description `"Windows Memory Diagnostic`"" | cmd
Start-Sleep -s 10

Write-Host "Restart Computer" -ForegroundColor Yellow
Restart-Computer
