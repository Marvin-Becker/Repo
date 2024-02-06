function mache-Dateien{
<#
.SYNOPSIS
Mein erstes Script
.DESCRIPTION
Parameter: LW, Ordnername, Dateiname, Anzahl
Ordner erstellen, wenn nicht vorhanden, 10 Dateien rein
.EXAMPLE
.\dateien.ps1 ....
.EXAMPLE
.\dateien.ps1 ....
.LINK
http://www.google.de
#>

param(
[ValidateSet("C","D")]$lw, 
[Parameter(Mandatory=$true)]$Foldername, 
[Parameter(Mandatory=$true)]$Filename, 
[int]$AnzahlDateien=10)

$pfad = $lw + ":\" + $Foldername
#$pfad = "$lw`:\$Foldername"

if(-not (Test-Path $pfad))                # -not kehrt Ergebnis um, alternativ: ! 
    {
    New-Item -Path $pfad -ItemType Directory
    }

# Erstellung von Dateien
  
for($i=1; $i -le $AnzahlDateien; $i++)
    {
    $Dateiname=("$Filename{0:D4}.txt" -f $i)
    New-item -Path $Pfad -Name $Dateiname -ErrorAction SilentlyContinue
    }
    }

# mache-Dateien c Ordner1 File 20

function test-test {
Write-Host "Ich teste." -ForegroundColor Red
}
