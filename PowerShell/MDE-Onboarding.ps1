function Set-MdeOnboarding() {
    <#
    .SYNOPSIS
        This Script will check all relevant settings of MDE for the specific OS Version.
		There are default values if not all parameters are set. You can also just choose a parameter for the customer settings (e.g. OGE).
		All results are written to the $Result variable and output at the end. There will be also an Eventlog entry with EventID 20.

    .NOTES
        Name: Set-MdeOnboarding
        Author: Marvin Krischker | KRIS085 | NMD-I2.1 | Marvin.Krischker@bertelsmann.de
        Date Created: 22.03.2022
        Last Update: 16.12.2022

    .EXAMPLE
        Set-MdeOnboarding @Parameter
		Set-MdeOnboarding -Customer OGE

    .LINK
        https://wiki.arvato-systems.de/display/WS/OGE+-+Microsoft+Defender+for+Endpoint+in+der+Cloud
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("OGE")]
        [string]$Customer,
        [Parameter(Mandatory = $false)]
        [string]$WorkSpace_ID,
        [Parameter(Mandatory = $false)]
        [string]$WorkSpace_Key,
        [Parameter(Mandatory = $false)]
        [ipaddress]$ProxyIP,
        [Parameter(Mandatory = $false)]
        [int64]$ProxyPort,
        [Parameter(Mandatory = $false)]
        [string]$Thumbprint,
        [Parameter(Mandatory = $false)]
        [string]$CertPath,
        [Parameter(Mandatory = $false)]
        [string]$MdeScriptPath
    )

    $ErrorActionPreference = "SilentlyContinue"
    # Customer Workspaces
    if ($PSBoundParameters.ContainsKey("Customer")) {
        switch ($Customer) {
            'OGE' {
                $WorkSpace_ID = "86ca6e41-0de5-447e-a508-bcbb8607c466"
                $WorkSpace_Key = "F4b26aTo2Q1EVPUlh3apcR25dpTSnfm4DJReGAnsB9QZ6ReBupU7ZelIZlsgz9yHUVmDnIWW6nudBEhgwIwCFQ=="
                $ProxyIP = "10.48.34.5"
                $ProxyPort = 8085
            }
        }
    }

    # Set Variables
    $Result = @("___________________________________")
    $DateStamp = Get-Date -UFormat "%Y-%m-%d @ %H-%M-%S"
    $Result += $DateStamp
    $Result += "-----------------------------------"
    $LogFile = "C:\SZIR\MDE-Onboarding.log"
    if (-not $PSBoundParameters.ContainsKey("Thumbprint")) {
        $Thumbprint = "d4de20d05e66fc53fe1a50882c78db2852cae474"
        $Certificate = "Baltimore Cybertrust Certificate"
    }
    if (-not $PSBoundParameters.ContainsKey("CertPath")) {
        $CertPath = "C:\SZIR\Baltimore CyberTrust.cer"
    }
    if (-not $Certificate) {
        $Certificate = "The requested Certificate"
    }
    if (-not $MdeScriptPath) {
        $MdeScriptPath = "C:\SZIR\WindowsDefenderATPLocalOnboardingScript.cmd"
    }
    $Proxy = "$ProxyIP`:$ProxyPort"

    # Get Variables from System
    $OSName = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    $Result += $OSName
    $OSversion = [version](Get-CimInstance Win32_OperatingSystem).Version
    $Disable = (Get-ItemPropertyValue 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name DisableEnterpriseAuthProxy) -match '1'
    $ProxySet = (Get-ItemPropertyValue 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name TelemetryProxyServer) -match $Proxy
    $MmaVersion = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup\' -Name AgentVersion

    # Check Certificate
    if (Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $Thumbprint }) {
        $Result += "+ $Certificate is already installed"
    } else {
        if (Test-Path $CertPath) {
            $Result += "- $Certificate is not installed, trying to add it now..."
            try {
                Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\Root -ErrorAction Stop
            } catch {
                $Result += "- Could not install $Certificate" + $Error[0]
                return $Result
                Exit
            }
            if (Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $Thumbprint }) {
                $Result += "+ $Certificate is installed now"
            } else {
                $Result += "- Could not install $Certificate" + $Error[0]
                return $Result
                Exit
            }
        } else {
            $Result += "- $Certificate missing in $CertPath"
            return $Result
            Exit
        }
    }

    # Check NetConnection
    $NetConnection = Test-NetConnection -ComputerName $ProxyIP -Port $ProxyPort
    if ((($NetConnection).TcpTestSucceeded) -eq $True) {
        $Result += "+ Proxy-Test true"
    } else { $Result += "- Proxy-Test false" }

    # Check special Update for Windows Server 2012
    if ($OSversion -eq [version]"6.3.9600") {
        $KB = "KB3080149"
        $Update = Get-HotFix | Where-Object HotFixID -EQ $KB
        if ($Update) {
            $HotFixID = $Update.HotFixId
            $InstalledOn = $Update.InstalledOn
            $Result += "+ Update $HotFixID installed on $InstalledOn"
            $BootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
            $Result += "-> Last BootTime $BootTime"
        } else {
            $Result += "- Update $KB missing"
        }
    }

    # Further steps are depending on OS Version
    # Lower than 2019:
    #if (($OSName -like "*2012*") -or ($OSName -like "*2016*")){
    if ($OSversion -ge [version]"10.0" -and $OSversion.Build -lt 17763) {

        if ($Disable -eq $True) {
            $Result += "+ DisableEnterpriseAuthProxy already disabled"
        } else {
            try {
                Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name DisableEnterpriseAuthProxy -Value 1 -ErrorAction Stop
                $Result += "- DisableEnterpriseAuthProxy set to 1"
            } catch {
                $Result += "- Could NOT set DisableEnterpriseAuthProxy" + $Error[0]
                return $Result
                Exit
            }
        }
        if ($ProxySet -eq $True) {
            try {
                Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name TelemetryProxyServer -ErrorAction Stop
                $Result += "- TelemetryProxy was set in Registry and removed now"
            } catch {
                $Result += "- Could NOT remove TelemetryProxy" + $Error[0]
                return $Result
                Exit
            }
        }
        # Check MMA config
        if ($MmaVersion -like "7*") {
            $Result += "- MMA Version $MmaVersion need to be updated"
        } elseif ($MmaVersion -like "10*") {
            $Result += "+ MMA Version $MmaVersion OK"
            $ProxySettings = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
            if ($ProxySettings.proxyUrl -ne $Proxy) {
                $ProxySettings.SetProxyInfo('', '', '')
                $Result += "- MMA Proxy is not correct and will be set now"
                $ProxySettings = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
                if ($ProxySettings.proxyUrl -eq $Proxy) {
                    $Result += "+ MMA Proxy is set"
                } else {
                    $Result += "- Could NOT set MMA Proxy"
                    return $Result
                    Exit
                }
            } elseif ($ProxySettings.proxyUrl -eq $Proxy) {
                $Result += "+ Proxy already in MMA"
            } else { $Result += "- No Proxy setting available" }
            $MMA = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
            $WorkSpace = $MMA.GetCloudWorkspace($WorkSpace_ID)
            if ($WorkSpace.workspaceId -eq $WorkSpace_ID) {
                $Result += "- Workspace ID already there, will set again"
                $MMA.RemoveCloudWorkspace($WorkSpace_ID)
                $MMA.ReloadConfiguration()
            } else {
                $Result += "- Workspace ID missing and will be set now"
            }
            $MMA.AddCloudWorkspace($WorkSpace_ID, $WorkSpace_Key)
            $MMA.ReloadConfiguration()
            Start-Sleep -Seconds 10
            $Spaces = $MMA.GetCloudWorkspaces()
            $Result += $Spaces
            $WorkSpace = $MMA.GetCloudWorkspace($WorkSpace_ID)
            $Status = $WorkSpace.ConnectionStatus
            $Result += "- Connection Status: $Status"
        } else {
            $Result += "- Could not detect MMA Version! Check if MMA is installed in any version." 
            return $Result
            Exit
        }
        [string]$Message = $Result

        # Cloud Connection Test Tool for configured Workspace
        $Result += cmd.exe /c "C:\Program Files\Microsoft Monitoring Agent\Agent\TestCloudConnection.exe"
    }

    # For OS 2019 or higher:
    #if (($OSName -like "*2019*") -or ($OSName -like "*2022*")){
    if ($OSversion -ge [version]"10.0" -and $OSversion.Build -ge 17763) {

        if ($Disable -eq $True) {
            $Result += "+ DisableEnterpriseAuthProxy already disabled"
        } else {
            try {
                Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name DisableEnterpriseAuthProxy -Value 1 -ErrorAction Stop
                $Result += "- DisableEnterpriseAuthProxy set to 1"
            } catch {
                $Result += "- Could NOT set DisableEnterpriseAuthProxy" + $Error[0]
                return $Result
                Exit
            }
        }
        if ($ProxySet -eq $True) {
            $Result += "+ Telemetry Proxy already there"
        } else {
            try {
                Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name TelemetryProxyServer -Value $Proxy -ErrorAction Stop
                $Result += "- Telemetry Proxy was wrong and now set correct"
            } catch {
                $Result += "- Could NOT set Telemetry Proxy" + $Error[0]
                return $Result
                Exit
            }
        }

        # Check MMA config
        if ($MmaVersion -like "7*") {
            $Result += "+ MMA Version $MmaVersion OK!"
        } elseif ($MmaVersion -like "10*") {
            $Result += "- MMA Version $MmaVersion, checking Config..."
            $ProxySettings = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
            if ($ProxySettings.proxyUrl) {
                $ProxySettings.SetProxyInfo('', '', '')
                $Result += "- MMA Proxy removed"
            } else { $Result += "+ No Proxy in MMA -> OK!" }
            $MMA = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
            $Space = (($MMA.GetCloudWorkspaces())[0]).WorkspaceID
            if ($Space) {
                do {
                    $Result += "- Detected Workspace $Space - will remove now..."
                    $MMA.RemoveCloudWorkspace($Space)
                    $MMA.ReloadConfiguration()
                    $Space = (($MMA.GetCloudWorkspaces())[0]).WorkspaceID
                } until (!$Space)
            } else {
                $Result += "+ No Workspace in MMA -> OK!"
            }
        } else { 
            $Result += "- Could not detect MMA Version! Check if MMA is installed in any version." 
            return $Result
            Exit
        }
        [string]$Message = $Result
        if (Test-Path $MdeScriptPath) {
            $Result += cmd.exe /c $MdeScriptPath
        } else {
            $Result += "- Oboarding-Script missing in $MdeScriptPath"
            $Result += "-> Run Onboarding-Script manually"
        }
    }
    $Result
    $Result >> $LogFile
    #Start-Process $LogFile

    # Eventlog-Entry
    $Source = "MDE-Onboarding"
    $SourceExist = [System.Diagnostics.EventLog]::SourceExists($Source);
    if (-not $SourceExist) {
        New-EventLog -LogName Application -Source $Source
    }
    $EventParameter = @{
        LogName   = "Application"
        Source    = $Source
        EventID   = 20
        EntryType = "Information"
        Message   = $Message + " | Logfile: $Logfile"
    }
    Write-EventLog @EventParameter
}

### Variante 1 ###
# direkter Funktionsaufruf mit kundenspezifischen Werten:
Set-MdeOnboarding -Customer OGE


### Variante 2 ###
# Parameter für Funktionsaufruf mit individuellen Werten (am Beispiel OGE):
$Parameter = @{
    WorkSpace_ID  = "86ca6e41-0de5-447e-a508-bcbb8607c466"
    WorkSpace_Key = "F4b26aTo2Q1EVPUlh3apcR25dpTSnfm4DJReGAnsB9QZ6ReBupU7ZelIZlsgz9yHUVmDnIWW6nudBEhgwIwCFQ=="
    ProxyIP       = "10.48.34.5"
    ProxyPort     = "8085"
}
# Funktionsaufruf mit Parameterliste
Set-MdeOnboarding @Parameter

###
#$SenseService = "C:\Program Files\Windows Defender Advanced Threat Protection\MsSense.exe"