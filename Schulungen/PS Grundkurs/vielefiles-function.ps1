
function Mach-Dateien{

<# 
.SYNOPSIS
Aufgabe:
.DESCRIPTION
Ordnernamen ausdenken
Pfad ggf. zusammenbauen
Prüfen, ob Ordner vorhanden, wenn nicht >> anlegen.
.EXAMPLE
.\vielefiles.ps1 -lw c ...
.EXAMPLE
.\vielefiles.ps1 -lw c ...
.LINK
https://google.de
#>

param(
[Parameter(Mandatory=$true,HelpMessage="Gib das LW an!")][ValidateSet("C","D","E")][string]$lw,
[Parameter(Mandatory=$true)][string]$ordner,
[int64]$Anzahl=100)

#$lw="c"
#$ordner="Test4"
#$Anzahl=100

$pfad=$lw+":\"+$ordner

# Ordner erstellen, wenn nicht vorhanden
if(!(Test-Path $pfad))
{
New-Item $pfad -ItemType Directory
}

# Dateien erstellen
for($i=1; $i -le $Anzahl; $i++)
{ 
$filename = "Datei{0:D3}.txt" -f $i
New-Item -Path $pfad -Name $filename -ItemType File
}
}

#main
#Mach-Dateien -lw C -ordner Test13 -Anzahl 10
