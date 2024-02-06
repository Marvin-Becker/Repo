#Power off Hibernation
"powercfg.exe /h off" | cmd

# Get ID of both Disks
$SystemDiskId = (Get-Disk | Where-Object { $_.IsBoot -eq "True" }).Number
$MirrorDiskId = (Get-Disk | Where-Object { $_.PartitionStyle -eq "RAW" }).Number

# Clean and convert Mirror-Disk
Write-Host "Clean and convert Mirror-Disk..." -ForegroundColor Yellow
$Convert = @(
    "select disk $MirrorDiskId",
    "online disk",
    "clean",
    "attributes disk clear readonly",
    "convert MBR",
    "select part 1",
    "delete partition override",
    "exit")
$Convert | diskpart

# Identify the System-Partition of the old System-Disk
$SystemPartition = (Get-Partition -DiskNumber $SystemDiskId | Where-Object { $_.IsSystem -eq ”True” }).PartitionNumber

$Assign = @(
    "select disk $SystemDiskId",
    "select part $SystemPartition",
    "assign letter=S",
    "exit")
$Assign | diskpart

# Convert both Disks to dynamic
Write-Host "Convert both Disks to dynamic..." -ForegroundColor Yellow
$ConvDyn = @(
    "select disk $SystemDiskId",
    "convert dynamic",
    "select disk $MirrorDiskId",
    "convert dynamic",
    "exit")
$ConvDyn | diskpart

# !!! After converting to dynamic you cannot use PowerShell commands to the Disks

Write-Host "Start Mirroring the S: Drive to Mirror-Disk..." -ForegroundColor Yellow
$AddDiskS = @(
    "select volume s",
    "add disk=$MirrorDiskId",
    "exit")
$AddDiskS | diskpart

# Start Mirroring the C: Drive to Mirror-Disk
Write-Host "Start Mirroring the C: Drive to Mirror-Disk..." -ForegroundColor Yellow
$AddDiskC = @(
    "select volume c",
    "add disk=$MirrorDiskId",
    "exit")
$AddDiskC | diskpart

# Check if the Mirroring-Process is done:
Write-Host "Check if the Mirroring-Process is done..." -ForegroundColor Yellow
do {
    $MirrorStatus = ("lis vol" | diskpart | Select-String -Pattern 'Boot' -context 0)[0] -match 'Healthy'
    Write-Host "Mirroring in process..." -ForegroundColor Yellow
    Start-Sleep -s 60
}
until ($MirrorStatus -eq "True")
Write-Host "Mirroring done!" -ForegroundColor Green


# Getting identifier for further edits on BCD
function Get-Identifier() {
    param(
        [Parameter(Mandatory = $True)]
        [ValidateSet("Device options", "Resume from Hibernate", "Windows Memory Tester")]
        $Pattern
    )
    $Id = $NULL
    bcdedit /enum all |
    Select-String -Pattern $Pattern -context 2 |
    ForEach-Object { $Id += ($_.Context.PostContext[1] -replace '^identifier +') }
    $Id = $Id.replace('}{', '},{')
    $Id = $Id.split(',')[0]
    return $Id
}

$DevOps = Get-Identifier -pattern "Device options"
$Resume = Get-Identifier -pattern "Resume from Hibernate"
$Memdiag = Get-Identifier -pattern "Windows Memory Tester"

$BootmgrNew = (bcdedit /enum all |
    Select-String -Pattern 'Windows Boot Manager - secondary plex' -context 2 |
    ForEach-Object { ($_.Context.PreContext[0] -replace '^identifier +') })

$WindowsNew = (bcdedit /enum OSLOADER |
    Select-String -Pattern '\w*secondary plex' -context 3 |
    ForEach-Object { ($_.Context.PreContext[0] -replace '^identifier +') })

Write-Host "Delete old Entries..." -ForegroundColor Yellow
"bcdedit /delete {current} /f" | cmd
"bcdedit /delete $BootmgrNew /f" | cmd
"bcdedit /delete $DevOps /f" | cmd
"bcdedit /delete $Resume /f" | cmd
"bcdedit /delete $Memdiag /f" | cmd

$DevOpsNew = Get-Identifier -pattern "Device options"
$ResumeNew = Get-Identifier -pattern "Resume from Hibernate"
$MemdiagNew = Get-Identifier -pattern "Windows Memory Tester"

Write-Host "Reorder the Boot Manager..." -ForegroundColor Yellow
"bcdedit /default $WindowsNew" | cmd
"bcdedit /displayorder $WindowsNew /addfirst" | cmd
"bcdedit /bootsequence $WindowsNew" | cmd
"bcdedit /toolsdisplayorder $MemdiagNew /addfirst" | cmd

Write-Host "Reset descriptions..." -ForegroundColor Yellow
"bcdedit /set $WindowsNew description `"Windows Server`"" | cmd
"bcdedit /set $DevOpsNew description `"Windows Recovery`"" | cmd
"bcdedit /set $ResumeNew description `"Windows Resume Application`"" | cmd
"bcdedit /set $MemdiagNew description `"Windows Memory Diagnostic`"" | cmd

Write-Host "Restart Computer" -ForegroundColor Yellow
Restart-Computer -Force
