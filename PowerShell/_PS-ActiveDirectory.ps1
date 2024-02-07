# AD Modul importieren
$ADModule = (Get-WindowsFeature -Name RSAT-AD-PowerShell).installed
if (-not($ADModule.installed)) {
    Add-WindowsFeature RSAT-AD-PowerShell
}
Import-Module ActiveDirectory

# Navigation im AD
## Befehle wie beim Verwalten von Ordnern im CMD möglich
cd ad:
cd "OU=USR,OU=group,DC=ASYSSERVICE,DC=de"
## OU erstellen
md "OU=ADMINS"

# Benutzer anlegen
$Passwd = ConvertTo-SecureString -String 'Pa$$wOrd' -AsPlainText -Force

New-ADUser -Name "Vorname Nachname" `
    -SamAccountName "AccountName" `
    -Path "OU=USR,OU=group,DC=ASYSSERVICE,DC=de" `
    -Enable $true `
    -AccountPassword $Passwd

# Benutzer
Get-ADUser -Identity "Name" -Properties *
Get-ADUser -Filter { City -eq "Dortmund" } | Set-AdUser -City "Gütersloh"
Get-ADUser -Filter { City -eq "Dortmund" } | Remove-ADUser # -Confirm:$False # löscht die Benutzer
Get-ADUser -Filter * -Searchbase "OU=USR,OU=group,DC=ASYSSERVICE,DC=de"
Get-ADUser "Name" -Property Memberof | Select-Object -ExpandProperty Memberof
Search-ADAccount -LockedOut [-AccountDisabled]
Set-ADAccountPassword [-Identity admin]

# Gruppen
New-ADGroup -Name "AdminGroup" -GroupScope Global -Path "OU=GRP,OU=group,DC=ASYSSERVICE,DC=de" 
$User = Get-ADUser -Filter { Department -eq "Windows Server" }
Add-ADGroupMember -Identity "AdminGroup" -Members $User
Get-ADGroupMember -Identity "AdminGroup" # -Recursive # zeigt alle User, die in Untergruppen sind, ohne die Untergruppen zu nennen
Add-Computer -Domain ASYSSERVICE.de -OUPath "OU=Server,OU=group,DC=ASYSSERVICE,DC=de" -Restart -Credential ASYSSERVICE\administrator


# OU in FQDN
$DistinguishedName = "OU=USR,OU=group,DC=ASYSSERVICE,DC=de"
$DistinguishedNameSplitted = $DistinguishedName -split (",DC=")
$FQDNString = ""
$ArrCount = 0
foreach ($Value in $DistinguishedNameSplitted) {
    if ($ArrCount -gt 0) {
        $FQDNString += $Value + "."
    }
    $ArrCount++
}
$FQDN = $FQDNString.substring(0, $FQDNString.length - 1)