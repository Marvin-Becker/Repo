function Get-NameFromSid () {
    Param(
        [Mandatory][string[]]$Sids
    )

    foreach ($SID in $Sids) {
        $User = (New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value
        Write-Output "$SID;$User"
    }
}
Get-NameFromSid