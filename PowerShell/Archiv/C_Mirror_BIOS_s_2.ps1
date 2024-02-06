$Logfile =  "C:\SZIR\BootLun.log"
$Abort = $False
$ErrorActionPreference = "SilentlyContinue"

#Power off Hibernation
"powercfg.exe /h off" | cmd >> $Logfile

# Get ID of both Disks
$SystemDiskId = (Get-Disk | Where-Object { $_.IsBoot -eq "True" }).Number
$MirrorDiskId = (Get-Disk | Where-Object { $_.PartitionStyle -eq "RAW" }).Number

if($NULL -eq $SystemDiskId){
    Write-Output "Error: No Boot Disk identified" >>$Logfile
    $Abort = $True
} else { 
    Write-Output "SystemDiskId: $SystemDiskId" >> $Logfile
}

if($NULL -eq $MirrorDiskId){
    Write-Output "Error: No Mirror Disk identified" >>$Logfile
    $Abort = $True
} else { 
    Write-Output "MirrorDiskId: $MirrorDiskId" >> $Logfile
}

if($Abort -eq $True){Exit}

# Clean and convert Mirror-Disk
Write-Output "Clean and convert Mirror-Disk..." >> $Logfile
$Convert = @(
    "select disk $MirrorDiskId",
    "online disk",
    "clean",
    "attributes disk clear readonly",
    "convert MBR",
    "select part 1",
    "delete partition override",
    "exit")
$Convert | diskpart >> $Logfile

# Identify the System-Partition of the old System-Disk
$SystemPartition = (Get-Partition -DiskNumber $SystemDiskId | Where-Object { $_.IsSystem -eq ”True” }).PartitionNumber

if($NULL -eq $SystemPartition){
    Write-Output "Error: No Boot Partition identified" >>$Logfile
    Exit
} else { 
    Write-Output "SystemPartition: $SystemPartition" >> $Logfile
}

[char[]]$Letters =  [char[]]([int][char]'K'..[int][char]'Z') 

foreach($Letter in $Letters) {
    try {
        Get-Volume -DriveLetter $Letter -ErrorAction Stop | Out-Null
    } catch {
        Write-Output "Free Letter $Letter found" >> $Logfile
        break
    }
}

$Assign = @(
  "select disk $SystemDiskId",
  "select part $SystemPartition",
  "assign letter=$Letter",
  "exit")
$Assign | diskpart >> $Logfile

if((Get-Volume -DriveLetter $Letter).DriveLetter -ne $Letter){
    Write-Output "Assigning $Letter did not work" >> $Logfile
    Exit
}

# Convert both Disks to dynamic
Write-Output "Convert both Disks to dynamic..." >> $Logfile
$ConvDyn = @(
    "select disk $SystemDiskId",
    "convert dynamic",
    "select disk $MirrorDiskId",
    "convert dynamic",
    "exit")
$ConvDyn | diskpart >> $Logfile

# !!! After converting to dynamic you cannot use PowerShell commands to the Disks

# Start Mirroring the System Reserved Partition to Mirror-Disk
Write-Output "Start Mirroring the System Reserved Partition to Mirror-Disk..." >> $Logfile
$AddDiskS = @(
    "select volume $Letter",
    "add disk=$MirrorDiskId",
    "exit")
$AddDiskS | diskpart >> $Logfile

# Start Mirroring the C: Drive to Mirror-Disk
Write-Output "Start Mirroring the C: Drive to Mirror-Disk..." >> $Logfile
$AddDiskC = @(
    "select volume c",
    "add disk=$MirrorDiskId",
    "exit")
$AddDiskC | diskpart >> $Logfile

# Check if the Mirroring-Process is done:
Write-Output "Check if the Mirroring-Process is done..." >> $Logfile
$Minutes = 0
do {
    $MirrorStatus = ("lis vol" | diskpart | Select-String -Pattern 'Boot' -context 0)[0] -match 'Healthy'
    Write-Output "Mirroring in process..." >> $Logfile
    Start-Sleep -s 60
    $Minutes++
}
until (($MirrorStatus -eq "True") -or ($Minutes -eq 60))
if($Minutes -eq 60){
  Write-Output "Mirroring C: failed! It took already $Minutes Minutes and was aborted. Please check." >> $Logfile
  Exit
}
Write-Output "Mirroring C: done! It took $Minutes Minutes." >> $Logfile

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


if(($NULL -eq $DevOps) -or (-not $DevOps.Contains("{"))){
    Write-Output "Error: Missing DevOps identifier" >> $Logfile
    $Abort = $True
} else { 
    Write-Output "Device options: $DevOps" >> $Logfile
}

if(($NULL -eq $Resume) -or (-not $Resume.Contains("{"))){
    Write-Output "Error: Missing Resume from Hibernate identifier" >> $Logfile
    $Abort = $True
} else { 
    Write-Output "Resume from Hibernate: $Resume" >> $Logfile
}

if(($NULL -eq $Memdiag) -or (-not $Memdiag.Contains("{"))){
    Write-Output "Error: Missing Memdiag identifier" >> $Logfile
    $Abort = $True
} else { 
    Write-Output "Windows Memory Tester: $Memdiag" >> $Logfile
}

if(($NULL -eq $BootmgrNew) -or (-not $BootmgrNew.Contains("{"))){
    Write-Output "Error: Missing Boot Manager - secondary plex identifier" >> $Logfile
    $Abort = $True
} else { 
    Write-Output "Windows Boot Manager - secondary plex: $BootmgrNew" >> $Logfile
}

if(($NULL -eq $WindowsNew) -or (-not $WindowsNew.Contains("{"))){
    Write-Output "Error: Missing Windows Server - secondary plex identifier" >> $Logfile
    $Abort = $True
} else { 
    Write-Output "Windows Server - secondary plex: $WindowsNew" >> $Logfile
}

if($Abort -eq $True){Exit}

Write-Output "Delete old Entries..." >> $Logfile
"bcdedit /delete {current} /f" | cmd >> $Logfile
"bcdedit /delete $BootmgrNew /f" | cmd >> $Logfile
"bcdedit /delete $DevOps /f" | cmd >> $Logfile
"bcdedit /delete $Resume /f" | cmd >> $Logfile
"bcdedit /delete $Memdiag /f" | cmd >> $Logfile

$DevOpsNew = Get-Identifier -pattern "Device options"
$ResumeNew = Get-Identifier -pattern "Resume from Hibernate"
$MemdiagNew = Get-Identifier -pattern "Windows Memory Tester"

if(($NULL -eq $DevOpsNew) -or (-not $DevOpsNew.Contains("{"))){
    Write-Output "Error: Missing new Device Options identifier" >> $Logfile
    $Abort = $True
} else { 
    Write-Output "New Device options: $DevOpsNew" >> $Logfile
}

if(($NULL -eq $ResumeNew) -or (-not $ResumeNew.Contains("{"))){
    Write-Output "Error: Missing new Resume from Hibernate identifier" >> $Logfile
    $Abort = $True
} else { 
    Write-Output "New Resume from Hibernate: $ResumeNew" >> $Logfile
}

if(($NULL -eq $MemdiagNew) -or (-not $MemdiagNew.Contains("{"))){
    Write-Output "Error: Missing new Windows Memory Tester identifier" >> $Logfile
    $Abort = $True
} else { 
    Write-Output "New Windows Memory Tester: $MemdiagNew" >> $Logfile
}

if($Abort -eq $True){Exit}

Write-Output "Reorder the Boot Manager..." >> $Logfile
"bcdedit /default $WindowsNew" | cmd >> $Logfile
"bcdedit /displayorder $WindowsNew /addfirst" | cmd >> $Logfile
"bcdedit /bootsequence $WindowsNew" | cmd >> $Logfile
"bcdedit /toolsdisplayorder $MemdiagNew /addfirst" | cmd >> $Logfile

Write-Output "Reset descriptions..." >> $Logfile
"bcdedit /set $WindowsNew description `"Windows Server`"" | cmd >> $Logfile
"bcdedit /set $DevOpsNew description `"Windows Recovery`"" | cmd >> $Logfile
"bcdedit /set $ResumeNew description `"Windows Resume Application`"" | cmd >> $Logfile
"bcdedit /set $MemdiagNew description `"Windows Memory Diagnostic`"" | cmd >> $Logfile
"bcdedit /enum all" | cmd >> $Logfile

Write-Output "Restart Computer" >> $Logfile
Restart-Computer -Force
