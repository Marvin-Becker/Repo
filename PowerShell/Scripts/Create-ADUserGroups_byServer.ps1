<#
.SYNOPSIS
    Creates administrator and RDP groups in Active Directory.
.DESCRIPTION
    This script Searches for administrator and rdp groups for the specified server in the domain. If not present or nested, the script creates the
    groups and nests them.
.INPUTS
    $ServerObject: The name of the server.
.OUTPUTS
    RC 0: Success
    RC 1: Reference group needed to determine domain readiness for automation could not be found or domain connection failed
    RC 2: Domain group could not be added to local permission group on the server
    RC 3: Permission could not be granted
#>

#region requirements
Import-Module ActiveDirectory
#endregion requirements

#region scriptblocks
[Scriptblock]$Return = {
    param (
        [String]$ReturnCode,
        [String]$ReturnMessage,
        [Switch]$ReturnError = $False
    )
    [String]$ReturnCode = 'RC=' + $ReturnCode
    Write-Output -InputObject $ReturnCode
    if ($ReturnError -eq $True) {
        [String]$ReturnMessage = 'Error=' + $ReturnMessage
        Write-Output -InputObject $ReturnMessage
    } else {
        [String]$ReturnMessage = 'Info=' + $ReturnMessage
        Write-Output -InputObject $ReturnMessage
    }
}
#endregion scriptblocks

#region input
[String]$ServerObject = 'extnlwvy16431'
#endregion input

#region local variables
[String]$GroupsPath = (Get-ADGroup -Identity 'Reference Group OU Path').DistinguishedName
[String]$GroupsPath = $GroupsPath.Remove(0, 27)
[String]$GlobalGroupOUPath = 'OU=User Tasks,' + $GroupsPath
[String]$LocalGroupOUPath = 'OU=Local Tasks Server,' + $GroupsPath

[Hashtable]$GlobalAdminParameter = @{
    Name           = $ServerObject + '_USR_LocalAdmin'
    SamAccountName = $ServerObject + '_USR_LocalAdmin'
    GroupCategory  = 'Security'
    GroupScope     = 'Global'
    DisplayName    = $ServerObject + '_USR_LocalAdmin'
    Path           = $GlobalGroupOUPath
}

[Hashtable]$DomainLocalAdminParameter = @{
    Name           = $ServerObject + '_LocalAdmin'
    SamAccountName = $ServerObject + '_LocalAdmin'
    GroupCategory  = 'Security'
    GroupScope     = 'DomainLocal'
    DisplayName    = $ServerObject + '_LocalAdmin'
    Path           = $LocalGroupOUPath
}

[Hashtable]$GlobalRDPParameter = @{
    Name           = $ServerObject + '_USR_RDP'
    SamAccountName = $ServerObject + '_USR_RDP'
    GroupCategory  = 'Security'
    GroupScope     = 'Global'
    DisplayName    = $ServerObject + '_USR_RDP'
    Path           = $GlobalGroupOUPath
}

[Hashtable]$DomainLocalRDPParameter = @{
    Name           = $ServerObject + '_RDP'
    SamAccountName = $ServerObject + '_RDP'
    GroupCategory  = 'Security'
    GroupScope     = 'DomainLocal'
    DisplayName    = $ServerObject + '_RDP'
    Path           = $LocalGroupOUPath
}
#endregion local variables

#region operations
#region group creation
try {
    Get-ADGroup -Identity ($ServerObject + '_LocalAdmin') | Out-Null
} catch {
    try {
        New-ADGroup @DomainLocalAdminParameter
    } catch {
        & $Return -ReturnCode 2 -ErrorMessage -ReturnMessage 'Permission group could not be created.'
    }
}

try {
    Get-ADGroup -Identity ($ServerObject + '_USR_LocalAdmin') | Out-Null
} catch {
    try {
        New-ADGroup @GlobalAdminParameter
    } catch {
        & $Return -ReturnCode 2 -ErrorMessage -ReturnMessage 'Permission group could not be created.'
    }
}

try {
    Get-ADGroup -Identity ($ServerObject + '_RDP') | Out-Null
} catch {
    try {
        New-ADGroup @DomainLocalRDPParameter
    } catch {
        & $Return -ReturnCode 2 -ErrorMessage -ReturnMessage 'Permission group could not be created.'
    }
}

try {
    Get-ADGroup -Identity ($ServerObject + '_USR_RDP') | Out-Null
} catch {
    try {
        New-ADGroup @GlobalRDPParameter
    } catch {
        & $Return -ReturnCode 2 -ErrorMessage -ReturnMessage 'Permission group could not be created.'
    }
}
#endregion group creation

#region group nesting
[String]$GlobalAdminGroup = $ServerObject + '_USR_LocalAdmin'
[String]$GlobalRDPGroup = $ServerObject + '_USR_RDP'
[String]$LocalAdminGroupMember = (Get-ADGroupMember -Identity ($ServerObject + '_LocalAdmin')).Name
[String]$LocalRDPGroupMember = (Get-ADGroupMember -Identity ($ServerObject + '_RDP')).Name
if ($GlobalAdminGroup -notin $LocalAdminGroupMember) {
    try {
        Add-ADGroupMember -Identity ($ServerObject + '_LocalAdmin') -Members $GlobalAdminGroup
    } catch {
        & $Return -ReturnCode 3 -ErrorMessage -ReturnMessage 'Permission group could not be nested.'
    }
}
if ($GlobalRDPGroup -notin $LocalRDPGroupMember) {
    try {
        Add-ADGroupMember -Identity ($ServerObject + '_RDP') -Members $GlobalRDPGroup
    } catch {
        & $Return -ReturnCode 3 -ErrorMessage -ReturnMessage 'Permission group could not be nested.'
    }
}
#endregion group nesting
#endregion operations

#region output
& $Return -ReturnCode 0 -ReturnMessage 'Groups have been created.'
#endregion output