<#
.Synopsis
    Build Group in active directory in ZOA-T-WN-SHARE-CREATE
.DESCRIPTION
    This Script runs in the Streamworksenviroment and
    is triggered by SDMS. Not for interactive use.
    Create the Domaingroups
    Runs with Domain Rights.
.NOTES
    Name: New-ShareDomain
    Author: Marvin Becker | KRIS085 | NMD-FS4.1 | Marvin.Becker@bertelsmann.de
    Date Created: 12.05.2023
    Last Update: 01.06.2023
#>

# Vars form SW
$ShareHost = "?{ServerName}"
$ShareDevice = "?{ShareDevice}"
$ShareName = "?{ShareName}"
$Description = "?{$ST_STREAM}"

[string]$Info = ''
$RC = 0
[string]$ErrorMessage = ''
[string]$ADGroup = $ShareHost + '_FS_' + $ShareName

if ( $ShareDevice -like 'C' ) {
    $ErrorMessage += 'Error: Drive C is not allowed here. '
    $RC = 1
    Write-Output "Info=$Info"
    Write-Output "RC=$RC"
    Write-Output "Error=$ErrorMessage"
    Exit
}

# create groups in active directory OU besides anchor
Add-WindowsFeature RSAT-AD-PowerShell | Out-Null
function Find-ArvatoTree {
    [CmdletBinding()]
    param ()

    $ADAnchor = 'Reference Group OU Path'
    try {
        $FullArvatoADPath = (Get-ADGroup -Filter { Name -like $ADAnchor } -ErrorAction Stop).DistinguishedName
    } catch {
        $RC = 1
    }
    if ($FullArvatoADPath) {
        $FullArvatoADPathArray = $FullArvatoADPath.Split( ',' , 2 )
        return $FullArvatoADPathArray[-1]
    } else {
        return $RC
    }
}

$ADBaseOU = Find-ArvatoTree

if ( $ADBaseOU -eq 1 ) {
    $ErrorMessage += 'Error: AD-Anchor-Group not found. '
    $RC = 1
    Write-Output "Info=$Info"
    Write-Output "RC=$RC"
    Write-Output "Error=$ErrorMessage"
    Exit
}

Foreach ( $AccessTAG in '_LF', '_RW', '_FA') {
    $DLGroup = $ADGroup + $AccessTAG + '_DL'
    if ( Get-ADGroup -filter { name -eq $DLGroup } ) {
        $Info += $DLGroup + ' already exists! '
    } else {
        try {
            New-ADGroup -Name $DLGroup -Path $ADBaseOU -GroupScope DomainLocal -Description $Description -ErrorAction Stop
            $Info += 'Created domain local group ' + $DLGroup + ' in ' + $ADBaseOU + '. '
        } catch {
            $ErrorMessage += 'Error: Could not create domain local AD-Group: ' + $DLGroup
            $RC = 1
        }
    }

    $GlobalGroup = $ADGroup + $AccessTAG + '_GG'
    if ( Get-ADGroup -filter { name -eq $GlobalGroup } ) {
        $Info += $GlobalGroup + ' already exists! '
    } else {
        try {
            New-ADGroup -Name $GlobalGroup -Path $ADBaseOU -GroupScope Global -Description $Description -ErrorAction Stop
            $Info += 'Created global group ' + $GlobalGroup + ' in ' + $ADBaseOU + '. '
        } catch {
            $ErrorMessage += 'Error: Could not create global AD-Group: ' + $GlobalGroup
            $RC = 1
        }
    }
    try {
        Add-ADGroupMember -Identity $DLGroup -Members $GlobalGroup -ErrorAction Stop
    } catch {
        $ErrorMessage += 'Error: Could not add the global AD-Group ' + $GlobalGroup + ' as a member of the local domain AD-Group ' + $DLGroup + '. '
        $RC = 1
    }
}

Write-Output "Info=$Info"
Write-Output "RC=$RC"
Write-Output "Error=$ErrorMessage"
