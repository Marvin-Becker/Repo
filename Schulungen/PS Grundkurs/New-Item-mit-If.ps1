
$Ordner=Read-Host "Gib den Ordnernamen an"
$Pfad="C:\"

if (-not(test-path $Pfad+$Ordner))
{new-item -Name $Ordner -Path $Pfad -ItemType Directory}


 