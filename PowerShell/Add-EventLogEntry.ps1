function Add-EventLogEntry {
    <#
    .SYNOPSIS
    Does basicly the same as Write-Eventlog. Tests if Logname and Source exist and creates them if not.
    Could be used to Filter possible Sources and Logs to a Range specifed be Arvato Systems Windows Server Team by using ValidateSet.

    .NOTES
    Name: Add-EventLogEntry
    Author: Sebastian Moock | Sebastian.Moock@bertelsmann.de
    Version: 1.1
    DateCreated:

    .EXAMPLE
    Add-EventLogEntry [-LogName] <string> [-Source] <string> [-EventId] <int> [[-EntryType] {Error | Information | FailureAudit | SuccessAudit | Warning}] [-Message] <string>  [<CommonParameters>]

.LINK

#>
    [CmdletBinding()]
    param(
        [Parameter( Mandatory = $true)]
        [string]$LogName,
        [Parameter( Mandatory = $true)]
        [string]$Source,
        [Parameter( Mandatory = $true)]
        [int]$EventID,
        [Parameter( Mandatory = $true)]
        [ValidateSet("Error", "Information", "FailureAudit", "SuccessAudit", "Warning")]
        [string]$EntryType,
        [Parameter( Mandatory = $true)]
        [string]$Message
    )
    $LogExist = [System.Diagnostics.EventLog]::Exists($eventLog);
    if (-not $LogExist) {
        New-EventLog -LogName $LogName
    }

    $SourceExist = [System.Diagnostics.EventLog]::SourceExists($Source);
    if (-not $SourceExist) {
        New-EventLog -LogName Application -Source $Source
    }

    $EventParameter = @{
        LogName   = $LogName
        Source    = $Source
        EventID   = $EventID
        EntryType = $EntryType
        Message   = $Message
    }

    Write-EventLog @EventParameter
}

#Aufruf:
$EventParameter = @{
    LogName   = "Application"
    Source    = "Anwendungsgrund"
    EventID   = "ID"
    EntryType = "Information"
    Message   = "Nachricht"
}
Add-EventLogEntry @EventParameter
 