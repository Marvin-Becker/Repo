# 1. Zahl: Zeit bis Box schließt, 2. Zahl variieren von 1..7 

$mbox=New-Object -com wscript.shell

$a = $mbox.popup("Auswahl",3,"Drück irgendwas",1)

switch($a){

1 {"OK"}
2 {"Abbrechen"}
10 {"wiederholen"}
11 {"weiter"}
}

$a