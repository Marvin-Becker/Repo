function Check-Status() {
    <#
    .SYNOPSIS
        This function can be used to check a status of something which is in process, e.g. and (Un-)Installation oder Disk Mirror.
        You need to change in $Status what you want to check.

    .NOTES
        Name: Check-Status
        Author: Marvin Krischker | KRIS085 | NMD-I2.1 | Marvin.Krischker@bertelsmann.de
        Date Created: 27.06.2022
        Last Update: 28.06.2022

    .EXAMPLE
        Check-Status -Path "Path"

    .LINK
        https://wiki.arvato-systems.de/
    #>

    [CmdletBinding()]
    [OutputType([String])]

    param(
        [string]$Path
    )

    $Minutes = 0
    do {
        $Status = Test-Path ($Path)
        Write-Output "Work in progress..."
        Start-Sleep -s 60
        $Minutes++
    }
    until (($Status -eq $False) -or ($Minutes -eq 60))
    if ($Minutes -eq 60) {
        Write-Output "Error: Something went wrong! It took already $Minutes Minutes and was aborted. Please check."
        Exit
    }
    Write-Output "Done! It took $Minutes Minutes."
}