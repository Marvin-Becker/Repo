# F7 für Kommando-Historie
# Strg J -> Beispiele von PowerShell
# Komplette Historie:
(Get-PSReadLineOption).HistorySavePath

# Output als Text wenn Zeichen nicht angezeigt werden können (auf Linux läuft)
$PSStyle.OutputRendering = 'PlainText'

# Debugging
Enter-PSHostProcess 
Debug-Process 

# Fehler bei langen Pfaden aushebeln:
"\\?\$Path\File.txt"

# Zeitstempel
$timestamp = Get-Date -UFormat "%d.%m.%Y %H:%M:%S"
$timestamp = Get-Date -UFormat "%Y.%m.%d %H:%M:%S"
$timestamp = (Get-Date).ToString("dd\.MM\.yyyy HH\:mm\:ss")

# Wert einer Variablen einsetzen
$ExecutionContext.InvokeCommand.ExpandString($_body)

$key = [Console]::ReadKey($true)
$value = $key.KeyChar

# OS detection
$domain = (Get-CimInstance win32_computersystem).Domain
$computersystem = Get-CimInstance win32_computersystem
$OSName = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
$OSversion = [version](Get-WmiObject Win32_OperatingSystem).Version

# Execution Policy
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
<#
Scope ExecutionPolicy
---------------------
MachinePolicy       Undefined
   UserPolicy       Undefined
      Process       Undefined
  CurrentUser      Restricted
 LocalMachine      Restricted
#>

# Konsolenereignisse mitschreiben:
Start-Transcript "Dateipfad"

# Befehle suchen, die zusammen gehören:
## Sortiert nach dem ersten Nomen
Get-Command | Sort-Object Noun
Get-Command -Module ServerManager

# Eigenen Alias für Befehl erstellen:
Set-Alias -Name XY -Value Get-Service

# Pipe | Möglichkeiten:
Get-Process | Sort-Object -Descending cpu | Select-Object CPU, ProcessName -First 5 | Where-Object { $_.CPU -ne $NULL }

## Pipe Formating
Get-Service | Format-List *
Get-Service | Format-Table displayname, status, requiredservices | Sort-Object -Property status
Get-Service | Sort-Object -Property status | Format-List displayname, status, requiredservices

### Pipe Gridview
Get-Service | Out-GridView
Get-Service | Format-Table displayname, status, requiredservices | Out-GridView
Get-Service | Select-Object displayname, status, requiredservices | Out-GridView
Get-Service | Select-Object * | Out-GridView
Get-Process | Out-GridView -PassThru | Stop-Process # Grafik zum Auswählen, welche Prozesse gestopt werden sollen

# Export von Dateien
Get-Service > Services.txt
Get-Service | Out-File c:\services.txt
Get-Service | Export-Csv c:\Services.csv
Get-HotFix | Select-Object CSName, Description, HotFixID, InstalledOn | Export-Csv -NoTypeInformation -Delimiter ";" -Path c:\temp\HotFix.csv

# Import von Dateien
Import-Csv Services.csv
Import-Csv Services.csv | Get-Member # Eigenschaften sehen
Import-Csv Services.csv -Delimiter ";" # wenn CSV mit Semikolon getrennt ist

# PowerShell Leveraging the ComputerName Parameter
Get-Service -ComputerName webserver, dcdsc | Select-Object * | Out-GridView
Get-Service -ComputerName dcdsc, webserver | Format-Table machinename, name, status
Get-Service -ComputerName dcdsc, webserver | Sort-Object -Property machinename | Format-Table machinename, name, status

# Search or Install Window Roles and Features
Get-WindowsFeature | Where-Object Installed -EQ $True
Get-WindowsFeature -Name *remote*
Get-WindowsFeature -Name Remote Desktop Services | Install-WindowsFeature
Add-WindowsFeature Remote Desktop Services

# Punktnotation für Objekteigenschaften und Methoden
(Get-ChildItem C:\Windows | Measure-Object -Property length -Sum).Sum / 1KB
Get-Service | Where-Object { $_.Status -eq "Running" }

"Hallo PowerShell".ToLower() # -> hallo powershell
"Hallo PowerShell".Substring(0, 5) # -> Erste Zahl = Startzeichen, zweite Zahl = Anzahl Zeichen -> Hallo
("OU=USR,OU=group,DC=ASYSSERVICE,DC=de".Split(",")[1]).Substring(3) # = group

# Capitalcase / Anfangsbuchstaben groß
$firstname = $ENV:USERNAME.Split('.')[0]
$surname = $ENV:USERNAME.Split('.')[1]
$name = (Get-Culture).TextInfo.ToTitleCase("$firstname $surname")

# Match
#  > $NULL entfernt die Ausgabe "True"
"Match" -match "Ma" # -> True
"Match1" -match "\d" # -> True
"123" -match "[a-z]" # -> False
"match" -cmatch "[a-z]" # -> True
"match" -cmatch "[A-Z]" # -> False
# Pattern begrenzen von Anfang bis Ende:
"^(\w{2,3})$" # -> Ziffern, mindestens 2, höchstens 3
"^(\w{2,3}[a-z])$" # -> Buchstaben, mindestens 2, höchstens 3
# egal was drum herum steht:
"\w{2,3}[a-z]"

"Test-123" -match "\w{2,3}[a-z]-\d{1,2}" # -> True
"Test-123" -match "^(\w{2,3}[a-z]-\d{1,2})$" # -> False
"Tes-12" -match "^(\w{2,3}[a-z]-\d{1,2})$" # -> True
"Tes-12" -match "^([a-z0-9-])+$" # -> True
"[ASY-Test_( 2.1 )] Test_( 2.1 )" -match '(\[ASY*[a-zA-Z0-9-_ ().] {1, 20}\] [a-zA-Z0-9-_ ().\[\]] {1, 50})'

$MirrorStatus = ("lis vol" | diskpart | Select-String -Pattern 'Boot' -Context 0)[0] -match 'Healthy'

bcdedit /enum all | Select-String -Pattern $Pattern -Context 2 | ForEach-Object { $Id += ($_.Context.PostContext[1] -replace '^identifier +') }
((netstat -anobv | Select-String -Pattern 8082 -Context 1).Context.PostContext[1]) -replace ' [ \[\]]' # -replace 'alt', 'neu'

$OSName = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption 
($OSName | Select-String -Pattern 'Windows' -Context 0) -match "[0-9]{2}" > $NULL
$OSVersion = $Matches.Values

# Objekte suchen
Get-ChildItem C: | Where-Object Length -GT 100MB
Get-ChildItem C: | Where-Object { $_.Length -gt 100MB -and $_.IsReadOnly -ne "True" }
(Get-ChildItem -Path "C:\temp" -Recurse | Where-Object Name -Like "TreeSizeFree.exe").FullName # -> C:\temp\TreeSizeFree.exe

# Objekte verarbeiten
"Ordner 1", "Ordner 2", "Ordner 3" | ForEach-Object { New-Item -Type Directory -Path $_ } # Ordner in aktueller Arbeitsumgebung ($_) anlegen

# Arrays
[string[]]$Servers = @()
## doppelte Werte löschen
$Servers = $Servers | Get-Unique

# Schleife mit immer neuer Variable
$index = 1
foreach ($item in $dataList) {
    $variable = "data$index"
    # Variable erstellen und den aktuellen Wert zuweisen
    New-Variable -Name $variable -Value $item
    $index++
}

# Hashtables
$Servers = @{
    "Server01" = "production"
    "Server02" = "tool"
}
foreach ($Server in $Servers.Keys) {
    # $Value = '{0}' -f $Servers[$Server]
    #$Value = $Servers[$Server]
    $Value = $Servers.$Server
    $Value
}

# schnelle Alternative zu Arrays (bei vielen neuen Einträgen)
$Arraylist = New-Object -TypeName "System.Collections.ArrayList"
$ArrayList.Add($a) | Out-Null

# Hashtable vergleichen
$Service = 'Streamworks'
$Processes = @{
    'Streamworks'   = 'StreamworksAgent'
    'Tanium Client' = 'TaniumClient'
    'Spooler'       = 'spoolsv'
}

if ( ($Processes.Keys).foreach( { $_ -like "$Service" }) -eq $true ) {
    $Process = $Processes["$Service"]
    $Process
} else {
    throw "Error: $Service not found in process list"
}
# oder:
if ($Processes.GetEnumerator().Name -contains $Service) {
    $Process = $Processes["$Service"]
    $Process
} else {
    $ServicesString = $Processes.GetEnumerator().Name -join ','
    throw 'The argument ' + $($Service) + ' does not match the following list: ' + $($ServicesString)
}

# Schleifen
for ($i = 0; $i -le 10; $i++) {
    $i
}
## oder:
1..10

## tu bis...
do {
} until (condition)

## tu solange...
do {
} while (condition)

## solange...
while (condition) {
    task
}

for ($a = 1; $a -le 5; $a++) {
    for ($i = 1; $i -le 5; $i++) {
        if ($i -eq 3) {
            break # bricht die aktuelle Schleife ab
            #exit # bricht den ganzen Ablauf/Script ab
        }
        Write-Output "$a  $i"
    }
}

# Werte abfragen
if (condition) {}
elseif (condition) {}
else {}

$IPConfig = "C:\temp\ipconfigall.txt"
if (Test-Path $IPConfig) {
    $DateStamp = Get-Date -UFormat "%Y-%m-%d@%H-%M-%S"
    $NewName = "ipconfigall_saved_$DateStamp.txt"
    Rename-Item $IPConfig -NewName $NewName
    $Result += "Old IPConfig saved in C:\temp\$NewName"
}

switch ($x) {
    condition {  }
    Default {}
}

switch -Wildcard ($x) {
    '*string*' {  }
    Default {}
}

switch ((Get-Date).Day) {
    1 { "1. Tag" }
    2 { "2. Tag" }
    Default { "Anderer Tag" }
}

switch ($PSCmdlet.ParameterSetName) {
    'Name' {
        Write-Host 'You used the Name parameter set.'
        break
    }
    'Id' {
        Write-Host 'You used the Id parameter set.'
        break
    }
}


while (($inp = Read-Host -Prompt "Wählen Sie einen Befehl") -ne "E") {
    switch ($inp) {
        R { Write-Host "Datei wird gelöscht" }
        S { Write-Host "Datei wird angezeigt" }
        L { Write-Host "Datei erhält Schreibschutz" }
        E { Write-Host "Ende" }
        default { Write-Host "Ungültige Eingabe" }
    }
}


# Funktionen
function Sum {
    $s = 0
    $Input | ForEach-Object { $s = $s + $_.Lenght }
    $s
}
## Funktion in Pipe aufrufen:
Get-ChildItem C:\Windows\*.log | sum

function FunctionName {
    param (
        $OptionalParameters
    )
    begin {} # Aufruf einmalig am Anfang
    process {} # Aufruf für jedes Objekt
    end {} # Aufrug einmalig am Ende
}

# prüft, ob optionaler Parameter vorhanden ist und verzweigt dann
function Show {
    param($para1, $para2)

    if ($PSBoundParameters.ContainsKey("para1")) {
        Get-Service $para1
    } else {
        Get-Service
    }
}
Show -para1 "spooler"

# Filter, die alle Objekte durchlaufen
filter Start-Backup {
    Copy-Item -Path $_ -Destination "C:\Backup"
}
Get-ChildItem C:\Windows\*.log | Start-Backup


# Scope
$a = 1
function f1 {
    $b = 2
    $Script:c = $a + $b
    $Global:d = $c * $b
    Write-Output "F1: A: $a B: $b C: $c D: $d"
}
f1
Write-Output "Script1: A: $a B: $b C: $c D: $d"

#zweites Script
.\Scope.ps1

Write-Output "Script2: A: $a B: $b C: $c D: $d"
<# Output:
F1: A: 1 B: 2 C: 3 D: 6
Script1: A: 1 B:  C: 3 D: 6
Script2: A: 1 B:  C: 3 D: 6
#>

# Remote PowerShell
Enable-PSRemoting # aktiviert alle relevanten PSRemote-Prozesse auf dem Zielrechner

Invoke-Command -ComputerName Server1, Server2, Server3 -ScriptBlock {  }

#Variablen mit $using:Variable an ScriptBlock übergeben
## Beispiel
$Cred = Get-Credential Administrator
$vms = (Get-VM win*).Name | Sort-Object
$i = 1
$DNS = 10.0.0.1

foreach ($vm in $vms) {
    $IP = "10.0.0.$i"
    Invoke-Command -VMName $vm -ScriptBlock {
        New-NetIPAddress -InterfaceAlias Ethernet -AddressFamily IPv4 -IPAddress $using:IP -PrefixLength 8 -DefaultGateway 10.0.0.254
        Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses $using:DNS
    } -Credential $Cred
    $i ++
}

# Profiles
## Hier kann man Funktionen ablegen, die für den User verfügbar sind
## Erstellen mit:
New-Item -Path $Profile -Type File -Force
## $Profile = %USERPROFILE%\Dokumente\PowerShell\Microsoft.PowerShell_profile.ps1

# Modules
## Verfügbar für alle User auf dem Computer
## Abspeichern als .psm1 unter C:\Program Files\WindowsPowerShell\Modules
## Aufrufbar über
Import-Module "Modul"
Get-Module -ListAvailable

# Shared Modules verbinden:
$env:PSModulePath = $env:PSModulePath + ";Path to shared module folder"
$env:PSModulePath += ";Path to shared module folder"

## Bedingungen eingeben mit:
##Requires -Version "N"[."n"]
##Requires -PSSnapin "PSSnapin-Name" [-Version "N"[."n"]]
##Requires -Modules { "Module-Name" | "Hashtable" }
##Requires -PSEdition "PSEdition-Name"
##Requires -ShellId "ShellId" -PSSnapin "PSSnapin-Name" [-Version "N"[."n"]]
##Requires -RunAsAdministrator

#ModuleManifest: weitere Infos über Module und deren Einstellungen der Übergabe von Variablen usw. können in einem Module Manifest .psd1 datei gespeichert werden


# Errorhandling
$ErrorActionPreference # "Continue" standardmäßig -> wenn Fehler, dann weiter machen
$ErrorActionPreference = "SilentlyContinue" # Fehler nicht sichtbar, aufrufbar in $? oder $Error
$ErrorActionPreference = "Stop" # Stopt weitere Verarbeitung
$ErrorActionPreference = "Inquire" # Fehlermeldung popt auf und fragt nach Aktion
## als Parameter:
-ErrorAction "SilentlyContinue" -ErrorVariable $Err

$ErrorView = 'NormalView' # Zeigt Fehler in einem detaillierten Format mit einer umfassenden Fehlermeldung, inklusive der vollständigen Ausnahmedetails und Stack-Trace.
$ErrorView = 'CategoryView' # Zeigt eine vereinfachte Fehlermeldung mit Fokus auf die Fehlerkategorie und -meldung, ohne tiefgehende Details.
$ErrorView = 'ConciseView' # (Standard ab PowerShell 7): Zeigt eine kompakte Fehlermeldung, die nur den relevanten Teil der Fehlermeldung enthält, um Lesbarkeit zu verbessern.
$ErrorView = 'DetailedView'

$? # letztes Ergebnis -> True oder False
if ($? -eq $False) { "Error:" + $Error[0] }


try {
    Befehl
} catch {
    "Error: " + $Error[0]
}

# Output
$rc = 0
[string]$info = ''
[string]$warning = ''
[string]$errorMessage = ''
$result = [PSCustomObject]@{
    'Returncode'   = $rc
    'Info'         = $info
    'Warning'      = $warning
    'Errormessage' = $errorMessage
}
return $result

### oder ###
$result = [PSCustomObject]@{
    'Returncode'   = '0'
    'Info'         = ''
    'Warning'      = ''
    'Errormessage' = ''
}
$result.Returncode = 'x'
$result.Info = 'x'
$result.Warning = 'x'
$result.Errormessage = 'x'
return $result