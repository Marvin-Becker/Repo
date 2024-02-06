function New-File() {
    <#
    .SYNOPSIS
        File-Creation

    .NOTES
        Name: New-File
        Author: Marvin Krischker | KRIS085 | NMD-I2.1 | Marvin.Krischker@bertelsmann.de
        Date Created: 14.06.2022
        Last Update:

    .EXAMPLE
        New-File -Drive C -FolderName temp -FileName Datei -Count 10

    .LINK

    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [ValidateSet("C", "D", "E")][ValidatePattern("^([c-eC-E])")][Parameter(Mandatory = $True, HelpMessage = "Drive between C and E")]
        $Drive,
        [Parameter(Mandatory = $True)]
        $FolderName,
        [ValidateLength(1, 10)][Parameter(Mandatory = $True, HelpMessage = "Maximum 10 Chars")]
        $FileName,
        [ValidateScript( { $_ -le 100 } )][ValidateRange(1, 100)][Parameter(Mandatory = $True, HelpMessage = "Count Maximum = 100")]
        [int]$Count
    )

    $Folder = $Drive + ":\" + $FolderName

    if (-not (Test-Path $Folder)) {
        New-Item -Type Directory -Path $Folder
    }

    for ($i = 1; $i -le $Count; $i++) {
        $File = "$FileName{0:D2}.txt" -f $i
        $Path = $Folder + "\" + $File

        if (-not (Test-Path $Path)) {
            New-Item -Type File -Path $Folder -Name $File
        }
    }
}
New-File -Drive -FolderName -FileName -Count