function mach-Inventur {
# verschiedene Daten zu einem (benutzerdefinierten) Objekt zusammenfassen
[CmdletBinding()]
param([string[]]$pcs)

#$pcs= Get-ADComputer -Filter * |select -ExpandProperty Name    # optional: Funktionsaufruf ändern

$Ergebnisse =[System.Collections.ArrayList]@()    # erzeugt/löscht leeres Arrayobjekt

foreach($pc in $pcs)
{
$LD = Get-CimInstance -ComputerName $pc -ClassName win32_logicaldisk -filter "DeviceID = 'C:'"
$freeCV = [math]::round($ld.FreeSpace/1GB,2)
$freeCP = [math]::round($ld.FreeSpace*100/$ld.Size,1)

$HF = Get-CimInstance -ComputerName $pc -ClassName win32_QuickFixEngineering 
$HFID = $HF.HotFixID

$neu=[PSCustomObject] @{Computer = $pc ;FreeProzent = $freeCP; FreeGB = $freeCV; HotFix = $HFID}
[void]$Ergebnisse.add($neu) 
}
$Ergebnisse |select  Computer,FreeGB, FreeProzent, HotFix
}

mach-Inventur "DC","S2" 