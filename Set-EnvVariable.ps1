Function Set-EnvVariable {
    <#
    .SYNOPSIS
        This is a basic overview of what the script is used for..

    .NOTES
        Name: 
        Author: Marvin Becker | Marvin.Becker@medavis.de
        Date Created: 
        Last Update:

    .EXAMPLE
        Set-EnvVariable -AddItem 'C:\temp\bin' -Variable 'Path' -Scope 'Machine' -Verbose

    .EXAMPLE
        Set-EnvVariable -RemoveItem 'C:\temp\bin' -Variable 'Path' -Scope 'User' -Verbose

    .LINK
        
    #>

    [CmdletBinding()]
    
    param (
        [Parameter(Mandatory = $false)]
        [string]$RemoveItem,

        [parameter(Mandatory = $false)]
        [string]$AddItem,

        [parameter(Mandatory = $true)]
        [string]$Variable,

        [Parameter(Mandatory = $true)]
        [ValidateSet('User', 'Machine')]
        [string]$Scope
    )
    $ErrorActionPreference = "Stop"

    #Get Current Path
    $Environment = [System.Environment]::GetEnvironmentVariable($Variable, $Scope)
    Write-Verbose "Current Environment for Variable $Variable in Scope '$Scope : "
    Write-Verbose $Environment

    #Remove Item from Path
    if ($PSBoundParameters.ContainsKey("RemoveItem")) {
        foreach ($Path in ($Environment).Split(";")) {
            if ($Path -like "*$RemoveItem*") {
                $Environment = $Environment.Replace($Path , "")
                Write-Verbose "Removed: $RemoveItem "
            }
        }
    }

    #Add Items to Environment
    if ($PSBoundParameters.ContainsKey("AddItem")) {
        $AddItemMod = ';' + $AddItem
        $Environment = $Environment.Insert($Environment.Length, $AddItemMod)
        Write-Verbose "Added: $AddItem "
    }

    #Set Updated Path
    try {
        [System.Environment]::SetEnvironmentVariable($Variable, $Environment, $Scope)
    } catch {
        Write-Output 'Variable ' + $Variable + 'in Scope ' + $Scope + ' could not been set!'
    }
}
