#Get Current Path
$Environment = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

#Remove Item from Path
$RemoveItem = 'C:\Program Files\OpenSSL-Win64\bin'
foreach ($path in ($Environment).Split(";")) {
    if ($path -like "*$RemoveItem*") {
        $Environment = $Environment.Replace($Path , "")
    }
}

#Add Items to Environment
$AddItem = ';' + 'C:\Program Files\OpenSSL-Win64\bin'
$Environment = $Environment.Insert($Environment.Length, $AddItem)

#Set Updated Path
[System.Environment]::SetEnvironmentVariable("Path", $Environment, "Machine")