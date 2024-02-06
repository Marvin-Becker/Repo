<# 
Aufgabe1: Ordner anlegen, wenn nicht vorhanden
Aufgabe2: 100 Dateien mit fortlaufender Nummer im Ordner erzeugen.
#>

$lw = "C"
$Foldername = "Folder6"
$Filename="Datei"
$AnzahlDateien=100

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
