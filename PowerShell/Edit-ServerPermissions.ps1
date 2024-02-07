<#
.SYNOPSIS
This script created domain local and global permission groups.

.DESCRIPTION
All computer objects in a managed  OU are collected and for each one RDP and local admin permission groups are created.
#>

<#
Author
Marvin Becker | NMD-I2.1 | Marvin.Becker@outlook.de
#>


# Installation of the AD powershell plugin, in case it shouldn't be there.
$ADModule = (Get-WindowsFeature -Name RSAT-AD-PowerShell).installed
if (-not ($ADModule.installed)) {
    Add-WindowsFeature RSAT-AD-PowerShell
}
Import-Module ActiveDirectory

# Definitions of some global variables that are not going to change.
$GlobalGroupOU = 'User Tasks'
$LocalGroupOU = 'Local Tasks Server'
$GroupPath = (Get-ADGroup -Identity 'Reference Group OU Path').DistinguishedName
$GroupPath = $GroupPath.Remove(0, 27)
$GlobalGroupOUPath = 'OU=' + $GlobalGroupOU + ',' + $GroupPath
$LocalGroupOUPath = 'OU=' + $LocalGroupOU + ',' + $GroupPath
$GlobalGroups = Get-ADGroup -Filter * -SearchBase $GlobalGroupOUPath
$LocalGroups = Get-ADGroup -Filter * -SearchBase $LocalGroupOUPath
$Servers = Get-ADComputer -Filter * | Where-Object { $_.DistinguishedNAme -notlike "*OU=Domain Controllers*" }

# Creation of the OUs where the groups are intended to be stored.
if (-not([adsi]::Exists("LDAP://$GlobalGroupOUPath"))) {
    New-ADOrganizationalUnit -Name $GlobalGroupOU -Path $GroupPath -ProtectedFromAccidentalDeletion $True
}

if (-not([adsi]::Exists("LDAP://$LocalGroupOUPath"))) {
    New-ADOrganizationalUnit -Name $LocalGroupOU -Path $GroupPath -ProtectedFromAccidentalDeletion $True
}

# Strings that wouldn't fit anywhere else.
$GlobalGroupAdminInfo = 'Darf nur von ASYS Windows Server Team bearbeitet werden !!; Nur f. Admin_RACF User od. tech Accounts mit NO Login'
$DomainLocalAdminInfo = 'Darf nur von ASYS Windows Server Team bearbeitet werden !!'
$GlobalGroupRDPInfo = 'Darf nur von ASYS Windows Server Team bearbeitet werden !!; Nur f. Admin_RACF User NICHT tech Accounts'
$DomainLocalRDPInfo = 'Darf nur von ASYS Windows Server Team bearbeitet werden !!'

# The actual creation of the groups itself.
foreach ($Object in $Servers) {
    # Splatting in order to shorten New-ADGroup.
    $GlobalAdminParameter = @{
        Name            = $Object.Name + "_USR_LocalAdmin"
        SamAccountName  = $Object.Name + "_USR_LocalAdmin"
        GroupCategory   = 'Security'
        GroupScope      = 'Global'
        DisplayName     = $Object.Name + "_USR_LocalAdmin"
        Path            = $GlobalGroupOUPath
        Description     = "User m. lokal Admin Rechte f. " + $Object.Name
        OtherAttributes = @{ info = $GlobalGroupAdminInfo }
    }

    $DomainLocalAdminParameter = @{
        Name            = $Object.Name + "_LocalAdmin"
        SamAccountName  = $Object.Name + "_LocalAdmin"
        GroupCategory   = 'Security'
        GroupScope      = 'DomainLocal'
        DisplayName     = $Object.Name + "_LocalAdmin"
        Path            = $LocalGroupOUPath
        Description     = "Local Admin Zugriff f. " + $Object.Name
        OtherAttributes = @{ info = $DomainLocalAdminInfo }
    }

    $GlobalRDPParameter = @{
        Name            = $Object.Name + "_USR_RDP"
        SamAccountName  = $Object.Name + "_USR_RDP"
        GroupCategory   = 'Security'
        GroupScope      = 'Global'
        DisplayName     = $Object.Name + "_USR_RDP"
        Path            = $GlobalGroupOUPath
        Description     = "User m. RDP Rechte f. " + $Object.Name
        OtherAttributes = @{ info = $GlobalGroupRDPInfo }
    }

    $DomainLocalRDPParameter = @{
        Name            = $Object.Name + "_RDP"
        SamAccountName  = $Object.Name + "_RDP"
        GroupCategory   = 'Security'
        GroupScope      = 'DomainLocal'
        DisplayName     = $Object.Name + "_RDP"
        Path            = $LocalGroupOUPath
        Description     = "RDP Zugriff f. " + $Object.Name
        OtherAttributes = @{ info = $DomainLocalRDPInfo }
    }

    if (-not (Get-ADGroup -Identity ($Object.Name + "_USR_LocalAdmin"))) { New-ADGroup @GlobalAdminParameter -ErrorAction SilentlyContinue }
    if (-not (Get-ADGroup -Identity ($Object.Name + "_LocalAdmin"))) { New-ADGroup @DomainLocalAdminParameter -ErrorAction SilentlyContinue }
    if (-not (Get-ADGroup -Identity ($Object.Name + "_USR_RDP"))) { New-ADGroup @GlobalRDPParameter -ErrorAction SilentlyContinue }
    if (-not (Get-ADGroup -Identity ($Object.Name + "_RDP"))) { New-ADGroup @DomainLocalRDPParameter -ErrorAction SilentlyContinue }
}

# Nesting of created global and local groups.
foreach ($Object in $Servers) {
    Add-ADGroupMember -Identity ($Object.Name + "_LocalAdmin") -Members ($Object.Name + "_USR_LocalAdmin") -ErrorAction SilentlyContinue
    Add-ADGroupMember -Identity ($Object.Name + "_RDP") -Members ($Object.Name + "_USR_RDP") -ErrorAction SilentlyContinue
}


# Removal of AD groups that no computer object exists for anymore.
# For global groups:
foreach ($Group in $GlobalGroups.Name) {
    $Index = $Group.IndexOf('_')
    $Object = $Group.Substring(0, $Index)

    If ($Object -notin $Servers.Name) {
        Remove-ADGroup -Identity $Group
    }
}

# For local groups:
foreach ($Group in $LocalGroups.Name) {
    $Index = $Group.IndexOf('_')
    $Object = $Group.Substring(0, $Index)

    If ($Object -notin $Servers.Name) {
        Remove-ADGroup -Identity $Group
    }
}