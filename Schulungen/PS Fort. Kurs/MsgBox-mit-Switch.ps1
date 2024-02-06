$mbox = New-Object -ComObject wscript.shell

$answer = $mbox.popup("Drücke bitte einen Knopf",0,"MessageBox-Test",2)

# erste Zahl: Zeit bis zum automatischen Schließen des Fensters
# zweite Zahl: MessageBox-Typ  (0..7)

switch($answer){
1 {"1 = Ok"}
2 {"2 = Abbrechen"}
3 {"3 = Abbrechen"}
4 {"4 = Wiederholen"}
5 {"5 = Ignorieren"}
6 {"6 = Ja"}
7 {"7 = Nein"}
10 {"10 = Wiederholen"}
11 {"11 = Weiter"}
default {"Nix von dem"}
}


"Ende"