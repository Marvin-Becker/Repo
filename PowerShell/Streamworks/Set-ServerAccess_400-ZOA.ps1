# Set-ServerAccess
<#
.Synopsis
Put user in the Accessgroups for RDP LA
.DESCRIPTION
This Script runs in the Streamworksenviroment and
is triggered by SDMS. Not for interactive use.
The Objects form users will put in the Localadmin
or in the RDPuser Group on the AD. User coma as
Limiters
.EXAMPLE
Set-ServerAccess
#>

# Vars form SW
$ServerObject = "?{servername}"
$Access = "?{accesstype}" # RDP, LOCALADMIN
$UsersObject = "?{users}"      # Users seperate with ","
$DRY_RUN = "?{dryrun}"     # True, False
#$Description    = "?{$ST_STREAM}

$SplitCar = ","
[string]$Info = "?{$&VINFO}"

$RC = 0
[string]$ErrorMessage = ''

$RegexServerObject = '^[a-zA-Z0-9\-]{1,15}$'
if ($ServerObject -notmatch $RegexServerObject) {
    $ErrorMessage = "The argument '$($ServerObject)' does not match the pattern '$($RegexServerObject)'"
    $ErrorCount++
}

$PossibleAccess = @( 'RDP', 'LOCALADMIN' )
if ($PossibleAccess -notcontains $Access) {
    $ErrorMessage = "The argument '$($Access)' does not match the following entries '$($PossibleAccess)'"
    $ErrorCount++
}

$RegexUsersObject = '^[a-zA-Z0-9\-,]{1,1024}$'
if ($UsersObject -notmatch $RegexUsersObject) {
    $ErrorMessage = "The argument '$($UsersObject)' does not match the following entries '$($RegexUsersObject)'"
    $ErrorCount++
}

if ($ErrorCount -ne 1) { return "$ErrorCount - ErrorMessage: $ErrorMessage" } 

# create groups in active directory OU besides anchor
Add-WindowsFeature RSAT-AD-PowerShell | Out-Null

try {
    Get-ADDomain -ErrorAction Stop | Out-Null
} catch {
    $ErrorMessage = "No Connect to AD Server"
    $ErrorCount++
}

# main
$groupNameAdminGG = $ServerObject + "_USR_LocalAdmin"
$groupNameRDPGG = $ServerObject + "_USR_RDP"
# Test a group
try {
    Get-ADGroup $groupNameRDPGG -ErrorAction Stop | Out-Null
} catch {
    $ErrorMessage = "AD Group $groupNameRDPGG not found"
    $ErrorCount++
}

# Users in Groups
foreach ( $User in ($UsersObject).Split($SplitCar) ) {
    # Test the User
    try {
        Get-ADUser $User -ErrorAction Stop | Out-Null
    } catch {
        $ErrorMessage = "AD User $User not found"
        $ErrorCount++
        Write-Output "Infomessage: $ErrorMessage"
    }
    # Put Users in Groups
    If ($Access -Eq "RDP") {
        try {
            Add-ADGroupMember -Identity $groupNameRDPGG -Members $User -ErrorAction Stop | Out-Null
            $ErrorCount = 0
        } catch {
            $ErrorMessage = "Can not put $User in Group $groupNameRDPGG"
            $ErrorCount++
        }
    } elseif ($Access -Eq "LOCALADMIN") {
        try {
            Add-ADGroupMember -Identity $groupNameAdminGG -Members $User -ErrorAction Stop | Out-Null
            $ErrorCount = 0
        } catch {
            $ErrorMessage = "Can not put $User in Group $groupNameAdminGG"
            $ErrorCount++
        }
    } else {
        $ErrorMessage = "Accesstype not 'RDP' or 'LOCALADMIN'"
    }
}

if ($ErrorCount -ne 0) {
    Write-Output "Errormessage: $ErrorMessage"
    exit 1;
} else {
    Write-Output "Infomessage: setting access ended ok"
    exit 0;
}
