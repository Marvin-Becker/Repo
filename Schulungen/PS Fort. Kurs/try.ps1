$VerbosePreference="continue"
try{
#1/0
#get-content D:\noaccess -ea Stop        # Erroraction Stop nötig, da Fehlerbehandlung im Command
import-csv d:\noaccess\datei.cs -EA stop -EV e    # Erroraction Stop NICHT nötig, da Fehler an PS übergeben - "terminierender" Fehler
#invoke-expression get-irgendwas -ErrorAction stop
Write-Host "hinter Einleseversuch" -ForegroundColor Green
}
catch [System.IO.FileNotFoundException] {
Write-host "Datei nicht gefunden" -ForegroundColor Yellow
write-verbose "Ich bin jetzt hier im Catch-Block"
#Write-Host $e -ForegroundColor Red
break
}
catch [System.UnauthorizedAccessException] {
Write-host "keine Berechtigung" -ForegroundColor Yellow
#Write-Host $e -ForegroundColor Red
break
}
catch [System.Management.Automation.ItemNotFoundException]{
Write-host "Item not found" -ForegroundColor Yellow
#break
}
catch {
Write-host "keine Ahnung warum" -ForegroundColor Yellow
}

#optional
Finally{
write-host "Finally wird immer ausgeführt" -ForegroundColor Yellow
write $e
}

write-host "Hinter FINALLY" -ForegroundColor Magenta