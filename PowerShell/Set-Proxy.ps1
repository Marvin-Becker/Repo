#Requires -Version 5.0
#region documentation
<#
    .SYNOPSIS
    Sets a proxy.

    .DESCRIPTION
    This script sets a proxy server either for the current user or systemwide.

    .EXAMPLE
    # Set a local proxy
    Set-Proxy -IP -Port

    # Set a systemwide proxy
    Set-Proxy -IP -Port -Global

    # Set a systemwide proxy for certain protocols
    Set-Proxy -IP 1.1.1.1 -HTTPPort 80 -FTPPort 21 -Global

    # Set a systemwide proxy with Bypasslist
    Set-Proxy -IP 10.16.97.119 -Port 3128 -Global -ByPassList "filetransfer.arvato-infoscore.de", "10.*"
    Set-Proxy -IP 172.26.56.254 -Port 8080 -Global -Bypasslist "172.26.*","*.alfa.local","127.0.0.*","*.tennet.eu"

    # Set proxy for currently logged in user which should use a configuration script
    Set-Proxy -Pac 'www.arvato-systems.com'

    .OUTPUTS
    Returns a PSCustomObject with the properties Returncode (Int32) and Returnmessage (String)
#>

<#
    Author
    Sebastian Moock | NMD-I2.1 | sebastian.moock@bertelsmann.de
#>
#endregion documentation


#region functions

function Set-Proxy() {
    [CmdletBinding(SupportsShouldProcess = $True)]
    [OutputType()]
    Param (
        [Parameter(Mandatory = $True)]
        [switch][bool]$Global,
        [Parameter(ParameterSetName = "Pac", Mandatory = $True)]
        [string]$Pac,
        [Parameter(ParameterSetName = "PortIP", Mandatory = $True)]
        [ipaddress]$IP,
        [Parameter(ParameterSetName = "PortIP", Mandatory = $False)]
        [int]$Port,
        [Parameter(ParameterSetName = "PortIP", Mandatory = $False)]
        [int]$HTTPPort,
        [Parameter(ParameterSetName = "PortIP", Mandatory = $False)]
        [int]$HTTPSPort,
        [Parameter(ParameterSetName = "PortIP", Mandatory = $False)]
        [int]$FTPPort,
        [Parameter(ParameterSetName = "PortIP", Mandatory = $False)]
        [int]$SocksPort,
        [Parameter(ParameterSetName = "PortIP", Mandatory = $False)]
        [string[]]$ByPassList
    )

    if ($Pac) {
        $propName = 'AutoConfigURL'
        $Proxy = $Pac
    } elseif ($IP) {
        $propName = 'ProxyServer'
        if ($HTTPPort -or $HTTPSPort -or $FTPPort -or $Socks) {
            if ($HTTPPort) {
                $Proxy = "http=$IP`:$HTTPPort;"
            }
            if ($HTTPSPort) {
                $Proxy += "https=$IP`:$HTTPSPort;"
            }
            if ($FTPPort) {
                $Proxy += "ftp=$IP`:$FTPPort;"
            }
            if ($SocksPort) {
                $Proxy += "socks=$IP`:$SocksPort;"
            }
        } else {
            $PropName = 'ProxyServer'
            $Proxy = "$ip`:$port"
        }
        if ($ByPassList) {
            $ByPassList += "<local>"
            [string]$ByPassList = $ByPassList -join ';'
        }
    }

    # Set entries
    $RegKey1 = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
    $RegKey2 = 'HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings'

    try {
        Set-ItemProperty -Path $RegKey1 -Name $PropName -Value $Proxy
        Set-ItemProperty -Path $RegKey1 -Name ProxyEnable -Value 1
        New-ItemProperty -Path $RegKey2 -Name ProxySettingsPerUser -ErrorAction SilentlyContinue | Out-Null
        if ($Global) {
            Set-ItemProperty -Path $RegKey2 -Name ProxySettingsPerUser -Value 0
        } else {
            Set-ItemProperty -Path $RegKey2 -Name ProxySettingsPerUser -Value 1
        }
        if ($ByPassList) {
            Set-ItemProperty -Path $RegKey1 -Name ProxyOverride -Value $ByPassList
        }
        Add-EventLogEntry
    } catch {
        Write-Warning "Proxy could not be set."
    }

    # Eventlog entry
    function Add-EventLogEntry {
        $Source = "Proxy"
        $SourceExist = [System.Diagnostics.EventLog]::SourceExists($Source);
        if (-not $SourceExist) {
            New-EventLog -LogName Application -Source $Source
        }
        if ($Global) {
            $EventParameter = @{
                LogName   = "Application"
                Source    = $Source
                EventID   = 124
                EntryType = "Information"
                Message   = "A global proxy setting has been set: $Proxy"
            }
        } else {
            $EventParameter = @{
                LogName   = "Application"
                Source    = $Source
                EventID   = 124
                EntryType = "Information"
                Message   = "A user proxy setting has been set: $Proxy"
            }
        }
        Write-EventLog @EventParameter
    }
}
