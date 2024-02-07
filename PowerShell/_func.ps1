Function Get-Something {
    <#
    .SYNOPSIS
        This is a basic overview of what the script is used for..

    .NOTES
        Name: 
        Author: Marvin Becker  | Marvin.Becker@outlook.de
        Date Created: 
        Last Update:

    .EXAMPLE
        Get-Something 'User1', 'User2' 'Server' 'ASYS-Order-0001217'

    .LINK
        https://wiki.server.de/
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
        [ValidatePattern('(20[0-9]{9}WEB|SD[0-9]{8}|IM[0-9]{9}|C[0-9]{10}|OMM_.+|ASYS-Order-[0-9]{7}|TESTING|MIGRATION)')]
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
Get-Something 'User1', 'User2' 'Server' 'ASYS-Order-0001217'
<# Output:
Start
Server
User1
User2
End
Reason
#>