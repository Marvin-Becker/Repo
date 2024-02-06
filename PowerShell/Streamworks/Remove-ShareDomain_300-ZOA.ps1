<#
.Synopsis
    delete Sharegroups in Domain
.DESCRIPTION
   This Script runs in the Streamworksenviroment and
   is triggered by SDMS. Not for interactive use.
   Delete the Share-Groups in AD.
   Runs with Domain Rights.
.NOTES
    Name: Remove-ShareDomain
    Author: Marvin Becker | KRIS085 | NMD-FS4.1 | Marvin.Becker@bertelsmann.de
    Date Created: 12.05.2023
    Last Update: 01.06.2023
#>

$ShareHost = "?{ServerName}"
$ShareName = "?{ShareName}"

[string]$Info = ''
$RC = 0
[string]$ErrorMessage = ''
[string]$ADGroup = $ShareHost + '_FS_' + $ShareName

# main
Add-WindowsFeature RSAT-AD-PowerShell | Out-Null

Foreach ( $AccessTAG in "_LF", "_RW", "_FA" ) {
    $DLGroup = $ADGroup + $AccessTAG + '_DL'
    if ( Get-ADGroup -filter { name -eq $DLGroup } ) {
        try {
            Remove-ADGroup -Identity $DLGroup -Confirm:$false -ErrorAction Stop
            $Info += ' Deleted: ' + $DLGroup
        } catch {
            $ErrorMessage += ' Cannot delete Group: ' + $DLGroup
            $RC = 1
        }
    } else {
        $ErrorMessage += ' AD Group not found: ' + $DLGroup
        $RC = 1
    }

    $GlobalGroup = $ADGroup + $AccessTAG + '_GG'
    if ( Get-ADGroup -filter { name -eq $GlobalGroup } ) {
        try {
            Remove-ADGroup -Identity $GlobalGroup -Confirm:$false -ErrorAction Stop
            $Info += ' Deleted: ' + $GlobalGroup
        } catch {
            $ErrorMessage += ' Cannot delete Group: ' + $GlobalGroup
            $RC = 1
        }
    } else {
        $ErrorMessage += ' AD Group not found: ' + $GlobalGroup
        $RC = 1
    }
}

Write-Output "Info=$Info"
Write-Output "RC=$RC"
Write-Output "Error=$ErrorMessage"