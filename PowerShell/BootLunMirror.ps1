<#
.SYNOPSIS
This script moves the Boot-LUN Disk to a new Disk.

.DESCRIPTION
The script will detect the current boot-disk and the new RAW disk and set up the mirror between them.
Then it configures the BCD to boot from the new disk. After a restart, the old disk can be removed and the mirror broken.

.NOTES
Author: Marvin Krischker | KRIS085 | NMD-FS4.1 | marvin.krischker@bertelsmann.de
Last Update: 02.03.2023
#>

$Logfile = "C:\SZIR\BootLun.log"
$ErrorActionPreference = "SilentlyContinue"

# Saving current BCD-file and BCD enum output
"bcdedit /export C:\SZIR\BCD_save" | cmd >> $Logfile
"bcdedit /enum all" | cmd >> "C:\SZIR\BCD_enum.txt"

# Power off Hibernation
"powercfg.exe /h off" | cmd >> $Logfile

# Functions
function Get-MirrorStatus {
    Write-Output "Check if the Mirroring-Process is done..." >> $Logfile
    [string]$Boot = ("lis vol" | diskpart | Select-String -Pattern 'Boot' -Context 0)
    if ($Boot.Contains('Healthy')) {
        $MirrorStatus = 'Healthy'
    } elseif ($Boot.Contains('Rebuild')) {
        $MirrorStatus = 'Rebuild'
    }
    return $MirrorStatus
}

function Get-MirrorTime {
    $Minutes = 0
    do {
        $Status = Get-MirrorStatus
        Start-Sleep -s 60
        $Minutes++
    } while (($Status -eq 'Rebuild') -and ($Minutes -le 60))
    # until (($Status -eq 'Healthy') -or ($Minutes -eq 60))

    if ($Minutes -eq 1) {
        Write-Output "Mirror did NOT start! Please check the reason." >> $Logfile
        Exit
    }

    return $Minutes
}

function Get-Mirror {
    param (
        [int]$Time
    )

    $MirrorStatusCheck = $false

    if ($Time -lt 60) {
        Write-Output "Mirroring C: done! It took $Time Minutes." >> $Logfile
        $MirrorStatusCheck = $true
    } elseif ($Time -eq 60) {
        Write-Output "Mirroring C: already took $Time Minutes. Please check in Disk Management." >> $Logfile
        Write-Output "Is the Mirror still in progress, done or failed? (Enter 'progress', 'done' or 'failed')" >> $Logfile
        do {
            $UserInput = Read-Host -Prompt "Is the Mirror still in progress, done or failed? (Enter 'progress', 'done' or 'failed')"
        }
        until ( ($UserInput -eq 'progress') -or ($UserInput -eq 'done') -or ($UserInput -eq 'failed'))

        if ($UserInput -eq 'progress') {
            Write-Output "User entered 'progress', checking Mirror-Process again..." >> $Logfile
            $Time = Get-MirrorTime
            if ($Time -lt 60) {
                $Time = $Time + 60
                Write-Output "Mirroring C: done! It took $Time Minutes." >> $Logfile
                $MirrorStatusCheck = $true
            } else { $MirrorStatusCheck = $false }
        } elseif ($UserInput -eq 'done') {
            Write-Output "User entered 'done', so mirroring C: is finish! It took $Time Minutes." >> $Logfile
            $MirrorStatusCheck = $true
        } elseif ($UserInput -eq 'failed') {
            Write-Output "User entered 'failed', so mirroring C: failed! Please check the reason." >> $Logfile
            Exit
        }
    }
    return $MirrorStatusCheck
}

function Get-Identifier() {
    param(
        [Parameter(Mandatory = $True)]
        [ValidateSet("Device options", "Resume from Hibernate", "Windows Memory Tester")]
        $Pattern
    )
    $Id = $NULL
    try {
        bcdedit /enum all | Select-String -Pattern $Pattern -Context 2 |
            ForEach-Object { $Id += ($_.Context.PostContext[1] -replace '^identifier +') }
        $Id = $Id.replace('}{', '},{')
        $Id = $Id.split(',')[0]
        return $Id
    } catch {
        Write-Output "Error: Identifier for $Pattern not found"
    }
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

# Getting identifier for further edits on BCD
$CustomObject = [pscustomobject]@{}
$CustomObject | Add-Member -type NoteProperty -Name DevOps -Value (Get-Identifier -pattern "Device options")
$CustomObject | Add-Member -type NoteProperty -Name Resume -Value (Get-Identifier -pattern "Resume from Hibernate")
$CustomObject | Add-Member -type NoteProperty -Name Memdiag -Value (Get-Identifier -pattern "Windows Memory Tester")

if ((Test-Object -CustomObject $CustomObject) -ne 0) {
    Write-Output "Error: An old identifier is missing" >> $Logfile
    Exit
} else {
    Write-Output "All old Identifiers were identified." >> $Logfile
}

# Get ID of both Disks
$SystemDiskId = (Get-Disk | Where-Object { $_.IsBoot -eq "True" }).Number
$MirrorDiskId = (Get-Disk | Where-Object { $_.PartitionStyle -eq "RAW" }).Number

if ($NULL -eq $SystemDiskId -or $NULL -eq $MirrorDiskId) {
    Write-Output "Error: No Boot Disk or Mirror Disk identified" >>$Logfile
    Write-Output "SystemDiskId: $SystemDiskId" >> $Logfile
    Write-Output "MirrorDiskId: $MirrorDiskId" >> $Logfile
    Write-Output "Check with Diskpart which Disk has which ID and enter it manually in this script in line 140 & 141." >> $Logfile
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
    Write-Output "Check with Diskpart which Partition is the System Partition and enter it manually in this script in line 168." >> $Logfile
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
    Write-Output "Assigning $Letter did NOT work. Check the reason and try again." >> $Logfile
    Exit
}

# Convert both Disks to dynamic
Write-Output "Convert both Disks to dynamic..." >> $Logfile
Write-Output "Notice: After converting to dynamic you cannot use PowerShell commands to the Disks anymore !!!" >> $Logfile
$ConvDyn = @(
    "select disk $SystemDiskId",
    "convert dynamic",
    "select disk $MirrorDiskId",
    "convert dynamic",
    "exit")
$ConvDyn | diskpart >> $Logfile

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
$MirrorStatusCount = 0
do {
    $Time = Get-MirrorTime
    $Check = Get-Mirror -Time $Time
    $MirrorStatusCount++
} until ( ($Check -eq $true) -or ($MirrorStatusCount -ge 2) )

if ($Check -eq $false) {
    Write-Output "Something is wrong with the mirror, please check the issue." >> $Logfile
    Exit
}

# Getting new Identifiers
$CustomObject | Add-Member -type NoteProperty -Name BootmgrNew -Value (bcdedit /enum all |
        Select-String -Pattern 'Windows Boot Manager - secondary plex' -Context 2 |
        ForEach-Object { ($_.Context.PreContext[0] -replace '^identifier +') })

if ((Test-Object -CustomObject $CustomObject) -ne 0) {
    Write-Output "Error: new Bootmgr identifier is missing"
    "bcdedit /import C:\SZIR\BCD_save" | cmd >> $Logfile
    Exit
} else {
    Write-Output "New Bootmgr Identifier was identified." >> $Logfile
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
$CustomObject | Add-Member -type NoteProperty -Name WindowsNew -Value (bcdedit /enum OSLOADER |
        Select-String -Pattern '\w*secondary plex' -Context 3 |
        ForEach-Object { ($_.Context.PreContext[0] -replace '^identifier +') })

if ((Test-Object -CustomObject $CustomObject) -ne 0) {
    Write-Output "Error: A new identifier is missing"
    "bcdedit /import C:\SZIR\BCD_save" | cmd >> $Logfile
    Exit
} else {
    Write-Output "All new Identifiers were identified." >> $Logfile
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

Write-Output "Moving Boot-LUN is done - Restarting the Computer..." >> $Logfile
Restart-Computer -Force
