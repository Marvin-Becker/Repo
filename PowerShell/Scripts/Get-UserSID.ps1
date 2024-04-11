function Get-NameFromSid () {
    Param(
        [Mandatory][string[]]$Users
    )

    foreach ($User in $Users) {
        $SID = (New-Object System.Security.Principal.NTAccount($User)).Translate([System.Security.Principal.SecurityIdentifier]).Value
        Write-Output "$User;$SID"
    }
}
Get-NameFromSid "majestics"