Get-SMBShare | Where-Object {$_.Name -notlike "*$*"} | Format-Table Name, Path

function Get-SharePermission {

# * = Abfrage eines bestimmten Share aus der Auflistung
    $ShareName = Read-Host "choose a share"
    Write-Host ""

    #Abfrage des Share-Pfades im Dateisystem für **
    $SharePath = (Get-SmbShare -Name $ShareName).Path
    $FolderList = Get-ChildItem -Directory -Path $SharePath -Recurse -Force

    #Zur Umgehung der AD Abfrage als PAM User für ***
    $ThisDomain = ((Get-LocalGroupMember -Group "Users" | Where-Object {($_.Name -like "*Domain*" -or $_.Name -like "*Domäne*")}).name).split("\")[0]

    foreach ($Folder in $FolderList) {

        #Abfrage aktueller Share-Berechtigungen
        $ShareSecurity = (Get-SmbShareAccess -Name $ShareName).AccountName

        # **/*** = Abfrage evtl. zukünftiger Share-Berechtigungen? Falls Everyone aktuell noch aktiviert ist und keine User im Share hinterlegt.
        $FolderSecurity = (Get-Acl -Path $SharePath).Access.IdentityReference | Where-Object {($_.Value -like "*$ThisDomain*" -and $_.Value -notlike "*SYSTEM*")} | fromat-table -hide

        #Auflistung der Berechtigungen für z.B.: SDM, Audit ect.
        Write-Host ""
        Write-Host "Current Share permission:"
        Write-Host $ShareSecurity
        Write-Host ""
        Write-Host "Current folder permission:"
        Write-Host $FolderSecurity

    }
}
Get-SharePermission