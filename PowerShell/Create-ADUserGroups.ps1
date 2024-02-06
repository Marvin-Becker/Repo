<#
.SYNOPSIS
This script created domain local and global permission groups.

.DESCRIPTION
All computer objects in a managed Arvato Systems OU are collected and for each one RDP and local admin permission groups are created.
#>

<#
Author
Sebastian Moock | NMD-I2.1 | sebastian.moock@bertelsmann.de
19.11.2021
#>


# Installation of the AD powershell plugin, in case it shouldn't be there.
$ADModule = (Get-WindowsFeature -Name RSAT-AD-PowerShell).installed
if (-not($ADModule.installed)) {
    Add-WindowsFeature RSAT-AD-PowerShell
}
Import-Module ActiveDirectory

# Definitions of some global variables that are not going to change.
$GlobalGroupOU = 'User Tasks'
$LocalGroupOU = 'Local Tasks Server'
$GroupPath = 'OU=GRP,OU=0997,OU=arvato systems group,DC=asysservice,DC=de'
$GlobalGroupOUPath = 'OU=' + $GlobalGroupOU + ',' + $GroupPath
$LocalGroupOUPath = 'OU=' + $LocalGroupOU + ',' + $GroupPath
$Server = (Get-ADComputer -Filter * | Where-Object { $_.DistinguishedNAme -notlike "*OU=Domain Controllers*" }).Name

# Creation of the OUs where the groups are intended to be stored.
New-ADOrganizationalUnit -Name $GlobalGroupOU -Path $GroupPath -ProtectedFromAccidentalDeletion $True
New-ADOrganizationalUnit -Name $LocalGroupOU -Path $GroupPath -ProtectedFromAccidentalDeletion $True

# Strings that wouldn't fit anywhere else.
$GlobalGroupAdminInfo = 'Darf nur von ASYS Windows Server Team bearbeitet werden !!; Nur f. Admin_RACF User od. tech Accounts mit NO Login'
$DomainLocalAdminInfo = 'Darf nur von ASYS Windows Server Team bearbeitet werden !!'
$GlobalGroupRDPInfo = 'Darf nur von ASYS Windows Server Team bearbeitet werden !!; Nur f. Admin_RACF User NICHT tech Accounts'
$DomainLocalRDPInfo = 'Darf nur von ASYS Windows Server Team bearbeitet werden !!'

# The actual creation of the groups itself.
foreach ($Object in $Server) {
    # Splatting in order to shorten New-ADGroup.
    $GlobalAdminParameter = @{
        Name            = $Object + "_USR_LocalAdmin"
        SamAccountName  = $Object + "_USR_LocalAdmin"
        GroupCategory   = 'Security'
        GroupScope      = 'Global'
        DisplayName     = $Object + "_USR_LocalAdmin"
        Path            = $GlobalGroupOUPath #'OU=User Tasks,OU=GRP,OU=0997,OU=arvato systems group,DC=asysservice,DC=de'
        Description     = "User m. lokal Admin Rechte f. " + $Object
        OtherAttributes = @{ info = $GlobalGroupAdminInfo }
    }

    $DomainLocalAdminParameter = @{
        Name            = $Object + "_LocalAdmin"
        SamAccountName  = $Object + "_LocalAdmin"
        GroupCategory   = 'Security'
        GroupScope      = 'DomainLocal'
        DisplayName     = $Object + "_LocalAdmin"
        Path            = $LocalGroupOUPath #'OU=Local Tasks Server,OU=GRP,OU=0997,OU=arvato systems group,DC=asysservice,DC=de'
        Description     = "Local Admin Zugriff f. " + $Object
        OtherAttributes = @{ info = $DomainLocalAdminInfo }
    }

    $GlobalRDPParameter = @{
        Name            = $Object + "_USR_RDP"
        SamAccountName  = $Object + "_USR_RDP"
        GroupCategory   = 'Security'
        GroupScope      = 'Global'
        DisplayName     = $Object + "_USR_RDP"
        Path            = $GlobalGroupOUPath #'OU=User Tasks,OU=GRP,OU=0997,OU=arvato systems group,DC=asysservice,DC=de'
        Description     = "User m. RDP Rechte f. " + $Object
        OtherAttributes = @{ info = $GlobalGroupRDPInfo }
    }

    $DomainLocalRDPParameter = @{
        Name            = $Object + "_RDP"
        SamAccountName  = $_ + "_RDP"
        GroupCategory   = 'Security'
        GroupScope      = 'DomainLocal'
        DisplayName     = $_ + "_RDP"
        Path            = $LocalGroupOUPath #'OU=Local Tasks Server,OU=GRP,OU=0997,OU=arvato systems group,DC=asysservice,DC=de'
        Description     = "RDP Zugriff f. " + $Object
        OtherAttributes = @{ info = $DomainLocalRDPInfo }
    }

    try {
        Get-ADGroup ($Object + "_USR_LocalAdmin")
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        New-ADGroup @GlobalAdminParameter -Verbose
    }
    try {
        Get-ADGroup ($Object + "_LocalAdmin")
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        New-ADGroup @DomainLocalAdminParameter
    }
    try {
        Get-ADGroup ($Object + "_USR_RDP")
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        New-ADGroup @GlobalRDPParameter
    }
    try {
        Get-ADGroup ($Object + "_RDP")
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        New-ADGroup @DomainLocalRDPParameter
    }
}

foreach ($Object in $Server) {
    Add-ADGroupMember -Identity ($Object + "_LocalAdmin") -Members ($Object + "_USR_LocalAdmin") -ErrorAction SilentlyContinue
    Add-ADGroupMember -Identity ($Object + "_RDP") -Members ($Object + "_USR_RDP") -ErrorAction SilentlyContinue
}