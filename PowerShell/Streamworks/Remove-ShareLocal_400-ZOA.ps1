<#
.Synopsis
    disable the share and delete folder
.DESCRIPTION
   This Script runs in the Streamworksenviroment and
  is triggered by SDMS. Not for interactive use.
   Delete the share and the folder.
   Runs with Local Rights.
.NOTES
    Name: Remove-ShareLocal
    Author: Marvin Becker | KRIS085 | NMD-FS4.1 | Marvin.Becker@bertelsmann.de
    Date Created: 12.05.2023
    Last Update: 01.06.2023
#>

#$ShareHost   = "?{ServerName}"
$ShareDevice = "?{ShareDevice}"
$ShareName = "?{ShareName}"
$Delete = "?{DeleteFolder}"

[string]$Info = "?{$&VINFO}"
$RC = 0
[string]$ErrorMessage = ''
$Path = $ShareDevice + ':\' + $ShareName

function Write-Log {
    param (
        [string]$Message
    )
    $Appsource = "SMBShare"
    $AppSourceExist = [System.Diagnostics.EventLog]::SourceExists( $AppSource )
    if ( -not $AppSourceExist ) {
        New-EventLog -LogName Application -Source $Appsource
    }
    $Messageparams = @{
        LogName     = "Application"
        Source      = $Appsource
        EventId     = "54001"
        EntryType   = "Information"
        Message     = "Remove-Share (local) - Result: $Message"
        ErrorAction = "SilentlyContinue"
    }
    Write-EventLog @Messageparams
}
# remove SMB-Share
try {
    Remove-SmbShare $ShareName -Force -ErrorAction Stop
    $Info += ' Removed Share: ' + $ShareName + '. '
} catch {
    $ErrorMessage += ' Cannot remove Share: ' + $ShareName + '. '
    $RC = 1
}

# remove directory
if ( $Delete -eq 'true' ) {
    try {
        Remove-Item -Path $Path -Force -ErrorAction Stop
        $Info += ' Removed Directory: ' + $Path
    } catch {
        $ErrorMessage += 'Cannot delete Directory: ' + $Path + '. '
        $RC = 1
    }
} else {
    $Info += ' Directory ' + $Path + ' not deleted.'
}
Write-Log -Message $Info
Write-Output "Info=$Info"
Write-Output "RC=$RC"
Write-Output "Error=$ErrorMessage"