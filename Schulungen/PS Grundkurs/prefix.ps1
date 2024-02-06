
$Prefix="Urlaub"
<#
NICHT so:
gci c:\ordner |foreach{Rename-Item $_.FullName ($Prefix+$_.Name)}

sondern so: (sonst Endlosschleife)

$dateien=gci c:\ordner2
$dateien |foreach{Rename-Item $_.FullName ($Prefix+$_.Name)}

oder noch besser:
#>

$dateien=gci c:\ordner2 

foreach($datei in $dateien)
{Rename-Item $datei.FullName ($Prefix+$datei.Name)}