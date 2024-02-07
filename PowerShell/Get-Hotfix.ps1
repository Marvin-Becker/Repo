function Get-InstalledHotfix {
    <#
    .SYNOPSIS
        This Script searches for the given Windows Update and returns if it is installed and when or not.

    .NOTES
        Name: 
        Author: Marvin Krischker  | Marvin.Krischker@outlook.de
        Date Created: 11.07.2022
        Last Update:

    .EXAMPLE
        Get-InstalledHotfix -Updates "KB5014701", "KB5014702"

    .LINK
        https://wiki.server.de/
    #>

    [CmdletBinding()]
    #[CmdletBinding(SupportsShouldProcess = $true)] # when changing system state
    [OutputType([String])]

    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Updates
    )

    $Result = @()

    foreach ($KB in $Updates) {
        $Update = Get-HotFix | Where-Object HotFixID -EQ $KB

        if ($Update) {
            $HotFixID = $Update.HotFixId
            $InstalledOn = $Update.InstalledOn
            $Result += "Update $HotFixID installed on $InstalledOn"
        } else {
            $Result += "Update $KB missing"
        }
    }
    return $Result
}
# Aufruf
Get-InstalledHotfix -Updates "KB5014702", "KB5014701"

## Alternative
Get-WmiObject -Class win32_quickfixengineering | Where-Object HotFixID -EQ KB3080149 

### Updates from today
Get-HotFix | Where-Object InstalledOn -EQ ([datetime]::Today)