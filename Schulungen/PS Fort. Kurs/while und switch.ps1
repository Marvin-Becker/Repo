
while(($inp = Read-Host -Prompt "Wählen Sie einen Befehl") -ne "Q"){

switch($inp){
 L {write-host "Datei wird gelöscht"
    break
 }
 A {write-host "Datei wird angezeigt"
    #exit
 }
 R {write-host "Datei erhält Schreibschutz"
    exit}
 E {write-host "Ende"}
 default {write-host "Ungültige Eingabe"}
 }
 }
 
 "Weiter mit Eingaben"