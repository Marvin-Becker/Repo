# New-ShareDomain
<#
.Synopsis
Build Group in active directory
.DESCRIPTION
This Script runs in the Streamworksenviroment and
is triggered by SDMS. Not for interactive use.
Create the Domaingroups
Runs with Domain Rights.
.EXAMPLE
New-ShareDomain
#>

# Vars form SW
$ShareHost = 'gtasswvw02155'
$ShareDevice = 'E'
$ShareName = 'TestShare'
#$Description = 'SSR_ZOA-Z-WN-SHARE-CREATE_0002'

$AD_Groups = $ShareHost + '_FS_' + $ShareName + '_DL'
$rc = 1

if ( $ShareDevice -like 'C' ) {
    Write-Output 'Errormessage: C ist not allowed here'
    $rc = 1
    exit 1
}

# create groups in active directory OU besides anchor
Add-WindowsFeature RSAT-AD-PowerShell | Out-Null
function Find-Tree {
    [CmdletBinding()]
    param ()

    $ADAnchor = 'Reference Group OU Path'
    try {
        $FullADPath = (Get-ADGroup -Filter { Name -like $ADAnchor } -ErrorAction Stop).DistinguishedName
    } catch {
        Write-Output 'Errormessage: AD-Anchor-Group not found'
    }
    $FullADPathArry = $FullADPath.Split( ',' , 2 )
    $FullADPathArry[-1]
}

$AD_Groups = $ShareHost + '_FS_' + $ShareName + '_DL'
$ADBaseOU = Find-Tree

Foreach ( $AccessTAG in '_LF', '_RW', '_FA') {
    $DLGroup = $AD_Groups + $AccessTAG
    if ( Get-ADGroup -filter { name -eq $DLGroup } ) {
        Write-Output 'Group exists!'
    } else {
        try {
            New-ADGroup -Name $DLGroup -Path $ADBaseOU -GroupScope DomainLocal -Description $Description -ErrorAction Stop
            $rc = 0
        } catch {
            Write-Output 'Errormessage: Could not create AD-Group'
            $rc = 1
            exit 1
        }
    }
}
$rc