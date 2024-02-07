
$loeschpfade = @(
    "c:\windows\temp\*",
    "c:\windows\*.tmp",
    "c:\windows\*.log",
    "c:\windows\Minidump\*",
    "c:\windows\*.dmp",
    "c:\temp\*",
    "C:\WINDOWS\Installer\`$PatchCache$\Managed\*",
    "C:\WINDOWS\Installer\Prefetch\*",
    "c:\windows\SoftwareDistribution\*",
    "c:\windows\ccmcache\*",
    "c:\`$Recycle.Bin",
    "c:\RECYCLER"
)

# Identification of user data on the drive and

$userOrdner = Get-ChildItem -Path C:\Users |
    where { $_.Attributes -eq "Directory" }
$userPfade = @()
foreach ($ordner in $userOrdner) {
    $userPfade += "C:\Users\" + $ordner + "\AppData\Local\Temp\*"
}

# Determination of the initial status

$freiVorher = Get-WmiObject Win32_LogicalDisk |
    Where-Object { $_.DeviceID -eq "C:" }
$groeßeSystemlaufwerk = "{0:N0}" -f ($freiVorher.Size / 1GB)
$freiVorherRelativ = ($freiVorher.Freespace / $freiVorher.Size)
$maschinentyp = Get-WmiObject -Class Win32_ComputerSystem

if ($maschinentyp.Model -like "*Virtual*") {
    Write-Host ("Client is a VM.") -ForegroundColor Green
} else {
    Write-Host ("Client is NOT a VM.") -ForegroundColor Red
}

Write-Host ("Drive C: has got " + $groeßeSystemlaufwerk + " GB in total") -ForegroundColor Cyan

Stop-Service -DisplayName "Windows Update"

if ($freiVorherRelativ -gt 0.1) {
    Write-Host ("Drive C: has currently got " + "{0:P2}" -f $freiVorherRelativ + " free space. This is above the threshold value.") -ForegroundColor Green
} else {
    Write-Host ("Drive C: has currently got " + "{0:P2}" -f $freiVorherRelativ + " free space. This is below the threshold value.") -ForegroundColor Red
}

# Actual cleaning of the files and folders

Write-Host "Clean up drive..."
foreach ($pfad in $loeschpfade) {
    Remove-Item $pfad -Force -Recurse -ErrorAction SilentlyContinue
}

foreach ($ordner in $userPfade) {
    $date = ((Get-Date).AddDays(-3)).ToShortDateString()
    Remove-Item $ordner -Recurse -Force -ErrorAction SilentlyContinue |
        where { $_.LastWriteTime -lt $Date }
}

# Calculation of the results

Start-Service -DisplayName "Windows Update"
$freiHinterher = Get-WmiObject Win32_LogicalDisk |
    Where-Object { $_.DeviceID -eq "C:" }
$freiGesamt = ($freiHinterher.FreeSpace - $freiVorher.FreeSpace)
$freiHinterherRelativ = ($freiHinterher.Freespace / $freiVorher.Size)

# The results of the cleaning operation

Write-Host ("A total of " + "{0:N2}" -f ($freiGesamt / 1Gb) + " GB were freed up on C:") -ForegroundColor Green

if ($freiHinterherRelativ -gt 0.1) {
    Write-Host ("Drive C: has got " + "{0:P2}" -f $freiHinterherRelativ + " free space now. There is enough memory free.") -ForegroundColor Green
} else {
    Write-Host ("Drive C: has got " + "{0:P2}" -f $freiHinterherRelativ + " free space now. This is above the threshold value. Drive may need to be extended.") -ForegroundColor Red
    $OpenTreeSize = $True
}

$freiVorherAbsolut = $FreiVorherRelativ * $groeßeSystemlaufwerk
$freiHinterherAbsolut = $freiHinterherRelativ * $groeßeSystemlaufwerk
$freiHinterherProzent = [math]::Round($FreiHinterherRelativ * 100, 2)
$freiHinterherGB = [math]::Round($FreiHinterherAbsolut, 2)

Write-Host "Clean-up performed. There are $FreiHinterherProzent % ($FreiHinterherGB GB) free now." -ForegroundColor Yellow

# Eventlog entries
$Source = "PowerShell Cleanup"
$SourceExist = [System.Diagnostics.EventLog]::SourceExists($Source);

if (-not $SourceExist) {
    New-Eventlog -LogName Application -Source "PowerShell Cleanup"
}

Write-EventLog -LogName Application -Source $Source -EventId 123 -EntryType Information -Message "The Systemdrive has been cleaned up."

### Open TreeSize
function Open-TreeSize {
    [string[]]$TreeSize = (Get-ChildItem -Path "C:\temp" -Recurse | Where-Object { ($_.Name -like "TreeSizeFree.exe") -OR ($_.Name -like "TreeSize.exe") }).Fullname

    if ($TreeSize) {
        Write-Output "Starting TreeSize..."
        Start-Process $TreeSize[0]
    } else {
        Write-Output "No TreeSize found. Will copy it from your System..."
        Copy-Item "\\tsclient\Z\Install\Tools\TreeSizeFree.exe" -Destination "C:\temp\BIN\" -Force
        if (Test-Path "C:\temp\BIN\TreeSizeFree.exe") {
            Write-Output "Starting TreeSize..."
            Start-Process "C:\temp\BIN\TreeSizeFree.exe"
        } else { Write-Output "Still no TreeSize found." }
    }
}
if ($OpenTreeSize -eq $True) { Open-TreeSize }