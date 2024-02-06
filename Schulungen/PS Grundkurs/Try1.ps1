"Es geht los"

Try{
#import-csv c:\user.csv -ErrorAction Stop       # Terminierender Fehler führt immer in Catch-Block - auch ohne Erroracton Stop

get-content c:\neu2\test.txt -ErrorAction Stop  -ErrorVariable egc   # Stop bei Nicht-terminierenden Fehler erforderlich !!!
#1/0

"Irgendwelche weiteren Cmdlets im Try-Block"
}

catch [System.UnauthorizedAccessException]{
"Zugriffsverweigerung"
#exit
}
catch [System.Management.Automation.ItemNotFoundException]{
"Datei nicht vorhanden  - get-content"
#exit
}
catch [System.IO.FileNotFoundException]{
"Datei nicht vorhanden  - Import-csv"
#exit
}

Catch{
"Allgemeiner Fehler"
#exit
}

Finally{
Write-Host  "Finally wir IMMER ausgeführt!" -ForegroundColor Yellow

Add-Content C:\Neu\log.txt -Value $egc
}


Write-Host  "Es geht munter weiter, wenn kein EXIT im Catch-Block" -ForegroundColor Green
