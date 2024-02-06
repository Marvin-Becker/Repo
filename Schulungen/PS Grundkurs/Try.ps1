
Try{
#get-content c:\services.tx -ErrorAction Stop
import-csv C:\test.csv -ErrorAction Stop
}
catch{
write-host "Fehler beim Lesen der Datei" -ForegroundColor Yellow 
exit
}
Finally{
write-host "Finally wir immer ausgeführt" -ForegroundColor Green
}


"Es geht immer weiter"