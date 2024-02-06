
#requires -modul Test
#requires -RunasAdministrator
#requires -Version 5.1

Set-StrictMode -off

$wert="Mahlzeit"

"Ausgabe: $wert"


(get-service spooler).status



"Alles ist toll"