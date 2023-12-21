Function Get-Something {
    <#
    .SYNOPSIS
        This is a basic overview of what the script is used for..

    .NOTES
        Name: 
        Author: Marvin Becker | Marvin.Becker@medavis.de
        Date Created: 
        Last Update:

    .EXAMPLE
        Get-Something 'User1', 'User2' 'Server'

    .LINK
        
    #>

    [CmdletBinding()]
    #[CmdletBinding(SupportsShouldProcess = $true)] # when changing system state
    [OutputType([String])]
    #[OutputType([PSCustomObject])]

    param (
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('User1', 'User2')]
        [Parameter(ParameterSetName = 'ParamSet')]
        [string[]]$UserName,

        [parameter(Position = 2, Mandatory = $false, HelpMessage = '')]
        [ValidatePattern('^[a-zA-Z0-9\-]{1,15}$')]
        [string]$Servername,

        [Parameter(Position = 3, Mandatory = $true)]
        [ValidatePattern('(INC[0-9]{6}|TESTING)')]
        [string]$Reason
    )

    <# Begin - Process - End
    Kommt immer dann zum Einsatz, wenn ein Array an eine Funktion übergeben wird.
    #>
    BEGIN {
        # einmaliger Aufruf, optional
        'Start'
        $Servername
    } 

    #Aufruf mehrmals über Pipeline möglich
    PROCESS {
        $UserName
    }
    
    # einmaliger Aufruf, optional
    END {
        'End'
        $Reason
    } 
}
Get-Something 'User1', 'User2' 'Server'
<# Output:
Start
Server
User1
User2
End
Reason
#>