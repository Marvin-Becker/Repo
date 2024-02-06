<#
.Synopsis
   .Net 3.5 installer for Windows Server 2012R2, 2016R1, 2019 and 2022.
.DESCRIPTION
   This script is only for installation of the .net 35 feature.
   It needs ManagedOS and two GB free HD Space. It will be used
   direcly from Streamworks and SDMS. Not for human use.
   The Port to the GTASSWVF05934 isn't open from all Server as
   expected. So the streamworks collegues first copied the install
   sources on the temp directory of C:
.EXAMPLE
   Install-DotNet35
#>
Param(
    [Parameter(Mandatory = $true)]
    [string]
    $Source
)
# Variablen
$ErrorActionPreference = 'silentlycontinue'
$WorkingDir = $Source + "\"
$global:rc = 0
$global:Info = @()

function Get-DotNet35Install {
    $global:Info += "Infomessage: Get-Install"
    $InstallStatus = (Get-WindowsFeature -name NET-Framework-Features).Installstate -eq "Installed"
    $global:Info += "InstallStatus: " + $InstallStatus
    return $InstallStatus
}

function Get-FreeSpace {
    $global:Info += "Infomessage: Get-FreeSpace"
    $SpaceRequired = 2 * 1024 * 1024 * 1024 # 2GB
    $SpaceFree = (Get-Volume -DriveLetter C ).SizeRemaining
    $global:Info += "SpaceFree: " + $SpaceFree
    return $SpaceFree -gt $SpaceRequired
}

function Get-WinVer {
    $global:Info += "Infomessage: Read Windows Version"
    $WinVer = (Get-CimInstance -class Win32_OperatingSystem).Caption
    $global:Info += "Windows Version: " + $WinVer
    return $WinVer
}

function Install-Dotnet {
    $global:Info += 'Infomessage: Installation'
    $Windows = (Get-WinVer).toString()
    $DotNetSource = (Get-ChildItem -Path $WorkingDir\ | Where-Object -FilterScript { $Windows -match $_.Name }).FullName + "\sxs"
    $global:Installation = @( Install-WindowsFeature -name NET-Framework-Features -Source $DotNetSource )
    if (Get-DotNet35Install) {
        $global:InstallResult += "Infomessage: Installation successfull!"
    } else {
        $global:InstallResult += "Errormessage: Installation failed with errors"
        $global:rc = 1
    }
}

function Find-NewVersion {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $global:Info += "Infomessage: Update Packages"
    # To create the searcher we use new Object , we store the returned Searcher #object in the $Searcher variable
    $Searcher = New-Object -ComObject Microsoft.Update.Searcher
    #Create the session with MS update
    $Session = New-Object -ComObject Microsoft.Update.Session
    #UpdateCollection Object to Store Windows updates ID based on our criteria
    $UpdateCollection = New-Object -ComObject Microsoft.Update.UpdateColl
    #To install a software Update we need to search for the updated and add it to 
    #the collection , download & install.
    try {
        $Findings = $Searcher.search("Type='software' AND IsInstalled = 0")
    } catch {
        $global:UpdateResult += "Infomessage: No connection to an upate source. Update manually please"
    }
    #We Explore the Findings from object the previous Searcher and we define title 
    #needs to be Security or Rollup!
    if ($PSCmdlet.ShouldProcess('.NetFramework 3.5', 'Windows update')) {
        $Findings.Updates | ForEach-Object {
            if ($_.Title -like '*.NET Framework 3.5*') {
                #Write-Host "Infomessage: "$_.Title
                #echo $_.Identity.UpdateID
                #Variable to Store identity of the Update ID
                $UpdateID = $_.Identity.UpdateID
                #Redefine Result with the wanted UPDATE ID
                $Find = $Searcher.Search("UpdateID='$UpdateID'")
                $Updates = $Find.updates
                #We do Add to the Update collection
                $UpdateCollection.Add($Updates.Item(0)) | Out-Null
                # Creating the Downloader
                $Downloader = $Session.CreateUpdateDownloader()
                #Passing the collection to the downloader
                $Downloader.Updates = $UpdateCollection
                #Downloading Updates
                $Downloader.Download()
                # Creating The object Installer
                $Installer = New-Object -ComObject Microsoft.Update.Installer
                #Passing the Installer to the update collection
                $Installer.Updates = $UpdateCollection
                #Installing the Updates
                $Installer.Install()
                $global:UpdateResult += '.NET Framework 3.5 Updates installed'
            }
        }
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
        Message     = ".NET Framework 3.5 was installed by Script - Result: $Errormessages"
        ErrorAction = "SilentlyContinue"
    }
    Write-EventLog @Messageparams
}

# Main()
if (!(Get-DotNet35Install)) {
    if (Get-FreeSpace) {
        try {
            Install-Dotnet
            if ((Get-DotNet35Install -eq $true)) {
                Find-NewVersion
                Write-Log
            }
        } catch {
            $_
            $global:Info += $_.Exception
            $global:rc = 1
        }
    } else {
        $global:Info += "Errormessage: Not enough space available for Installation."
        $global:rc = 2
    }
} else {
    $global:Info += "Infomessage: .Net 3.5 is already installed"
}

$Result = [PSCustomObject]@{
    'Returncode'      = $global:rc
    'InstallStatus'   = $global:InstallStatus
    'InstallResult'   = $global:InstallResult
    'UpdateResult'    = $global:UpdateResult
    'InstallationRun' = $global:Installation
    'Information'     = $global:Info
} | ConvertTo-Json
return $Result