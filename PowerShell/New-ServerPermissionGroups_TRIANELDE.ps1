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

Start-Transcript -Path 'C:\temp\Scripting\New-ServerPermissionGroups\Log.txt'

# Installation of the AD powershell plugin, in case it shouldn't be there.
$ADModule = (Get-WindowsFeature -Name RSAT-AD-PowerShell).installed
if (-not ($ADModule.installed)) {
    Add-WindowsFeature RSAT-AD-PowerShell
}
Import-Module ActiveDirectory

try {
    Get-ADGroup -Identity 'Reference Group OU Path'
} catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Return 'Domain is not prepared yet, reference group OU path not found.'
}

# Definitions of some global variables that are not going to change.
$GlobalGroupOU = 'User Tasks'
$LocalGroupOU = 'Local Tasks Server'
$GroupsPath = (Get-ADGroup -Identity 'Reference Group OU Path').DistinguishedName
$GroupsPath = $GroupsPath.Remove(0, 27)
$GlobalGroupOUPath = 'OU=User Tasks,' + $GroupsPath
$LocalGroupOUPath = 'OU=Local Tasks Server,' + $GroupsPath
#$GlobalGroups = Get-ADGroup -Filter * -SearchBase $GlobalGroupOUPath
#$LocalGroups = Get-ADGroup -Filter * -SearchBase $LocalGroupOUPath
$ServerPaths = @('OU=SRV,OU=ASYS-Managed-Servers,OU= GmbH,DC=trianel,DC=de')


# Creation of the OUs where the groups are intended to be stored.
New-ADOrganizationalUnit -Name $GlobalGroupOU -Path $GroupsPath -ProtectedFromAccidentalDeletion $True -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name $LocalGroupOU -Path $GroupsPath -ProtectedFromAccidentalDeletion $True -ErrorAction SilentlyContinue


# Strings that wouldn't fit anywhere else.
$GlobalGroupAdminInfo = 'Darf nur von ASYS Windows Server Team bearbeitet werden !!; Nur f. Admin_RACF User od. tech Accounts mit NO Login'
$DomainLocalAdminInfo = 'Darf nur von ASYS Windows Server Team bearbeitet werden !!'
$GlobalGroupRDPInfo = 'Darf nur von ASYS Windows Server Team bearbeitet werden !!; Nur f. Admin_RACF User NICHT tech Accounts'
$DomainLocalRDPInfo = 'Darf nur von ASYS Windows Server Team bearbeitet werden !!'


# The actual creation of the groups itself.
foreach ($Path in $ServerPaths) {
    $Servers = Get-ADComputer -Filter 'Enabled -eq "True"' -SearchBase $Path
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
		
        try {
            Get-ADGroup -Identity ($Object.Name + "_USR_LocalAdmin")
        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            New-ADGroup @GlobalAdminParameter
        }
		
        try {
            Get-ADGroup -Identity ($Object.Name + "_LocalAdmin")
        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            New-ADGroup @DomainLocalAdminParameter
        }
		
        try {
            Get-ADGroup -Identity ($Object.Name + "_USR_RDP")
        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            New-ADGroup @GlobalRDPParameter
        }
		
        try {
            Get-ADGroup -Identity ($Object.Name + "_RDP")
        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            New-ADGroup @DomainLocalRDPParameter
        }
    }
}


# Nesting of created global and local groups.
foreach ($Object in $Servers) {
    Add-ADGroupMember -Identity ($Object.Name + "_LocalAdmin") -Members ($Object.Name + "_USR_LocalAdmin") -ErrorAction SilentlyContinue
    Add-ADGroupMember -Identity ($Object.Name + "_RDP") -Members ($Object.Name + "_USR_RDP") -ErrorAction SilentlyContinue
}

Stop-Transcript
