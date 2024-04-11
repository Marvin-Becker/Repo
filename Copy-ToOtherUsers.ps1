# Verzeichnis, in dem die settings.json-Datei liegt
$sourceFilePath = "C:\Users\marvin.becker\AppData\Roaming\Code\User\settings.json"

# Zielverzeichnis, in das die Datei kopiert werden soll
$destinationDirectory = "\APPDATA\Roaming\Code\User"

# Überprüfen, ob die settings.json-Datei existiert
if (-not (Test-Path $sourceFilePath)) {
    Write-Host "Die Datei $sourceFilePath existiert nicht."
    exit
}

# Abrufen einer Liste aller Benutzerprofile auf dem Server
$users = "C:\Users\anna.goldammer",
"C:\Users\dominik.kowalski",
"C:\Users\christian.liebmann",
"C:\Users\andreas.neurath"

# Durchgehen jedes Benutzerprofils und Kopieren der settings.json-Datei
foreach ($user in $users) {
    $userDirectory = Join-Path -Path $user -ChildPath $destinationDirectory

    # Überprüfen, ob das Benutzerverzeichnis existiert
    if (Test-Path $userDirectory) {
        $destinationFilePath = Join-Path -Path $userDirectory -ChildPath "settings.json"
        
        # Kopieren der Datei in das Benutzerverzeichnis
        Copy-Item -Path $sourceFilePath -Destination $destinationFilePath -Force
        Write-Host "Die Datei wurde nach $destinationFilePath kopiert."
    } else {
        Write-Host "Das Benutzerverzeichnis für $user wurde nicht gefunden."
    }
}
