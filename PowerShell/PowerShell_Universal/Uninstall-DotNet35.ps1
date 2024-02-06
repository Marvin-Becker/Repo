<#
.Synopsis
   .Net 3.5 Uninstaller for Windows Server 2012R2, 2016R1, 2019 and 2022.
.DESCRIPTION
   This script is only to uninstall the .NET 3.5 feature.
   It needs ManagedOS and two GB free HD Space. It will be used
   direcly from Streamworks and SDMS. Not for human use.
   The Port to the GTASSWVF05934 isn't open from all Server as
   expected. So the streamworks collegues first copied the install
   sources on the temp directory of C:
#>
Param()
# Variablen
$ErrorActionPreference = 'silentlycontinue'
$global:rc = 0
$global:Info = @()

function Get-DotNet35Install {
    $global:Info += "Infomessage: Get-Install"
    $global:InstallStatus = (Get-WindowsFeature -name NET-Framework-Features).Installstate -eq "Installed"
    $global:Info += "InstallStatus: " + $global:InstallStatus
    return $global:InstallStatus
}

function Uninstall-Dotnet {
    $global:Info += 'Infomessage: Uninstallation'
    $global:Uninstallation = @( Uninstall-WindowsFeature -name NET-Framework-Features )
    if (!(Get-DotNet35Install)) {
        $global:UninstallResult += "Infomessage: Uninstallation successfull!"
    } else {
        $global:UninstallResult += "Errormessage: Uninstallation failed with errors"
        $global:rc = 1
    }
}

function Write-Log {
    param (
        [string]$Errormessages
    )
    $Appsource = "dotnet35"
    $AppSourceExist = [System.Diagnostics.EventLog]::SourceExists($AppSource);
    if (-not $AppSourceExist) {
        New-EventLog -LogName Application -Source $Appsource
    }
    $Messageparams = @{
        LogName     = "Application"
        Source      = $Appsource
        EventId     = "53001"
        EntryType   = "Information"
        Message     = ".NET Framework 3.5 was uninstalled by Script - Result: $Errormessages"
        ErrorAction = "SilentlyContinue"
    }
    Write-EventLog @Messageparams
}

# Main()
if ((Get-DotNet35Install)) {
    try {
        Uninstall-Dotnet
        if ((Get-DotNet35Install -eq $false)) {
            Write-Log
        }
    } catch {
        $_
        $global:Info += $_.Exception
        $global:rc = 1
    }
} else {
    $global:Info += "Errormessage: Not enough space available for software package."
    $global:rc = 2
} else {
    $global:Info += "Infomessage: .Net 3.5 is already not installed"
}

$Result = [PSCustomObject]@{
    'Returncode'        = $global:rc
    'InstallStatus'     = $global:InstallStatus
    'UninstallResult'   = $global:UninstallResult
    'UninstallationRun' = $global:Uninstallation
    'Information'       = $global:Info
} | ConvertTo-Json
return $Result