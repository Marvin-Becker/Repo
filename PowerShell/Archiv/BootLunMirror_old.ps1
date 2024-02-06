<#
.SYNOPSIS
This script moves the Boot-LUN Disk to a new Disk.

.DESCRIPTION
The script will detect the current boot-disk and the new RAW disk and set up the mirror between them.
Then it configures the BCD to boot from the new disk. After a restart, the old disk can be removed and the mirror broken.

.NOTES
Author: Marvin Krischker | KRIS085 | NMD-I2.1 | marvin.krischker@bertelsmann.de
Last Update: 29.06.2022
#>

$Logfile = "C:\SZIR\BootLun.log"
$ErrorActionPreference = "SilentlyContinue"

# Saving current BCD-file and BCD enum output
"bcdedit /export C:\SZIR\BCD_save" | cmd
"bcdedit /enum all" | cmd >> "C:\SZIR\BCD_enum.txt"

#Power off Hibernation
"powercfg.exe /h off" | cmd >> $Logfile

# Get ID of both Disks
$SystemDiskId = (Get-Disk | Where-Object { $_.IsBoot -eq "True" }).Number
$MirrorDiskId = (Get-Disk | Where-Object { $_.PartitionStyle -eq "RAW" }).Number

if ($NULL -eq $SystemDiskId -or $NULL -eq $MirrorDiskId) {
    Write-Output "Error: No Boot Disk or Mirror Disk identified" >>$Logfile
    Write-Output "SystemDiskId: $SystemDiskId" >> $Logfile
    Write-Output "MirrorDiskId: $MirrorDiskId" >> $Logfile
    Exit
} else {
    Write-Output "SystemDiskId: $SystemDiskId" >> $Logfile
    Write-Output "MirrorDiskId: $MirrorDiskId" >> $Logfile
}

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

if ($NULL -eq $SystemPartition) {
    Write-Output "Error: No Boot Partition identified" >>$Logfile
    Exit
} else {
    Write-Output "SystemPartition: $SystemPartition" >> $Logfile
}

[char[]]$Letters = [char[]]([int][char]'K'..[int][char]'Z')

foreach ($Letter in $Letters) {
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

if ((Get-Volume -DriveLetter $Letter).DriveLetter -ne $Letter) {
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
    $MirrorStatus = ("lis vol" | diskpart | Select-String -Pattern 'Boot' -Context 0)[0] -match 'Healthy'
    Write-Output "Mirroring in process..." >> $Logfile
    Start-Sleep -s 60
    $Minutes++
}
until (($MirrorStatus -eq "True") -or ($Minutes -eq 60))
if ($Minutes -eq 60) {
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
    bcdedit /enum all | Select-String -Pattern $Pattern -Context 2 |
        ForEach-Object { $Id += ($_.Context.PostContext[1] -replace '^identifier +') }
    $Id = $Id.replace('}{', '},{')
    $Id = $Id.split(',')[0]
    return $Id
}

function Test-Object {
    param(
        [parameter(Mandatory = $True)]
        [PSCustomObject] $CustomObject
    )
    $ErrorCount = 0
    $AllObjects = $CustomObject.psobject.Members | Where-Object membertype -Like 'noteproperty'
    foreach ($obj in $AllObjects) {
        if (($NULL -eq $obj.Value) -or (-not $obj.Value.Contains("{"))) {
            Write-Output "Error: Missing $($obj.Name) identifier" >> $Logfile
            $ErrorCount++
        } else {
            Write-Output "$($obj.Name): $($obj.Value)" >> $Logfile
        }
    }
    return $ErrorCount
}

$CustomObject = [pscustomobject]@{}
$CustomObject | Add-Member -type NoteProperty -Name DevOps -Value (Get-Identifier -pattern "Device options")
$CustomObject | Add-Member -type NoteProperty -Name Resume -Value (Get-Identifier -pattern "Resume from Hibernate")
$CustomObject | Add-Member -type NoteProperty -Name Memdiag -Value (Get-Identifier -pattern "Windows Memory Tester")

$CustomObject | Add-Member -type NoteProperty -Name BootmgrNew -Value (bcdedit /enum all |
        Select-String -Pattern 'Windows Boot Manager - secondary plex' -Context 2 |
        ForEach-Object { ($_.Context.PreContext[0] -replace '^identifier +') })

$CustomObject | Add-Member -type NoteProperty -Name WindowsNew -Value (bcdedit /enum OSLOADER |
        Select-String -Pattern '\w*secondary plex' -Context 3 |
        ForEach-Object { ($_.Context.PreContext[0] -replace '^identifier +') })

if ((Test-Object -CustomObject $CustomObject) -ne 0) {
    Write-Output "See log for missing value"
    Exit
}

Write-Output "Delete old Entries..." >> $Logfile
$Delete = @(
    "bcdedit /delete {current} /f",
    "bcdedit /delete $($CustomObject.BootmgrNew) /f",
    "bcdedit /delete $($CustomObject.DevOps) /f",
    "bcdedit /delete $($CustomObject.Resume) /f",
    "bcdedit /delete $($CustomObject.Memdiag) /f" )
$Delete | cmd >> $Logfile

$CustomObject | Add-Member -type NoteProperty -Name DevOpsNew -Value (Get-Identifier -pattern "Device options")
$CustomObject | Add-Member -type NoteProperty -Name ResumeNew -Value (Get-Identifier -pattern "Resume from Hibernate")
$CustomObject | Add-Member -type NoteProperty -Name MemdiagNew -Value (Get-Identifier -pattern "Windows Memory Tester")

if ((Test-Object -CustomObject $CustomObject) -ne 0) {
    Write-Output "See log for missing value"
    Exit
}

Write-Output "Reorder the Boot Manager..." >> $Logfile
$Reorder = @(
    "bcdedit /default $($CustomObject.WindowsNew)",
    "bcdedit /displayorder $($CustomObject.WindowsNew) /addfirst",
    "bcdedit /bootsequence $($CustomObject.WindowsNew)",
    "bcdedit /toolsdisplayorder $($CustomObject.MemdiagNew) /addfirst")
$Reorder | cmd >> $Logfile

Write-Output "Reset descriptions..." >> $Logfile
$Descriptions = @(
    "bcdedit /set $($CustomObject.WindowsNew) description `"Windows Server`"",
    "bcdedit /set $($CustomObject.DevOpsNew) description `"Windows Recovery`"",
    "bcdedit /set $($CustomObject.ResumeNew) description `"Windows Resume Application`"",
    "bcdedit /set $($CustomObject.MemdiagNew) description `"Windows Memory Diagnostic`"")
$Descriptions | cmd >> $Logfile

"bcdedit /enum all" | cmd >> $Logfile

Write-Output "Moving Boot-LUN is done - Restarting the Computer..." >> $Logfile

$Source = "Boot-LUN Mirror"
$SourceExist = [System.Diagnostics.EventLog]::SourceExists($Source);
if (-not $SourceExist) {
    New-EventLog -LogName Application -Source $Source
}

$EventParameter = @{
    LogName   = "Application"
    Source    = $Source
    EventID   = 85
    EntryType = "Information"
    Message   = "Boot-LUN Mirror performed. Logfile: $Logfile"
}
Write-EventLog @EventParameter

Restart-Computer -Force
