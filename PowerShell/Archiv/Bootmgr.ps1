# !!! After Restart: (DiskNumber need to be entered manually) !!!
Write-Host "Check if the Sync-Process is done..." -ForegroundColor Yellow
do{
    $mirrorstatus = ("for /f `"tokens=8 delims= `" %a IN ('echo list volume ^| diskpart ^| find `"Boot`"') do echo %a") | cmd
    Write-Host "Sync in process..." -ForegroundColor Yellow
    Start-Sleep -s 10
}
until ($mirrorstatus -eq "Healthy")
Write-Host "Sync done!" -ForegroundColor Green
Write-Host "Breaking Mirror..." -ForegroundColor Yellow
	[array]$breakmirror = @(
	"select volume c",
	"break disk 0 nokeep",
	"exit")
	$breakmirror | diskpart

	"bcdedit /displayorder {default} /remove" | cmd
	"bcdedit /default {current}" | cmd

Write-Host "Clean and set offline old Disk..." -ForegroundColor Yellow
	[array]$offline = @(
	"select disk 0",
  "offline disk",
	"clean",
	"exit")
	$offline | diskpart.exe

Write-Host "Change Boot-Partition..." -ForegroundColor Yellow
	[array]$assignefi = @(
	"select disk 1",
	"select vol 0",
	"assign letter=S",
	"exit")
	$assignefi | diskpart

  [array]$changeletters = @(
	"select disk 0",
	"select part 2",
	"remove letter=S",
	"select disk 1",
	"select part 1",
	"assign letter=S",
	"exit")
	$changeletters | diskpart

	"bcdedit /set {bootmgr} device `"partition=S:`"" | cmd

	# oder
	"bcdedit /set {bootmgr} device `"partition=\Device\HardDiskVolume1`"" | cmd

	"bcdedit /set {bootmgr} path `"\EFI\Microsoft\Boot\bootmgfw.efi`"" | cmd
