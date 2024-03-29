function Set-NewIpAddress {
    <#
    .SYNOPSIS
        This Script will change the IP Settings for Dialog IP and / or Backup IP.
        You can enter just Dialog or Backup values or both.
        If you forget a mandatory parameter it will not run and tell you why.
    .NOTES
        Name: Set-NewIpdAdress
        Author: Marvin Krischker  | Marvin.Krischker@outlook.de
        Date Created: 26.11.2021
        Last Update: 21.12.2022
    .EXAMPLE
        Set-NewIpAddress -DialogIP 10.0.0.4 -DialogPrefix 8 -DialogGateway 10.0.0.1 -DialogDNS1 10.0.0.2 -BackupIP 10.0.0.13 -BackupPrefix 8 -BackupGateway 10.0.0.11 -Reason "Ticket"
        Set-NewIpAddress -DialogIP 10.0.0.4 -DialogPrefix 8 -DialogGateway 10.0.0.1 -DialogDNS1 10.0.0.2 -Reason "Ticket"
        Set-NewIpAddress -BackupIP 10.0.0.13 -BackupPrefix 8 -BackupGateway 10.0.0.11 -Reason "Ticket"
        Set-NewIpAddress @Parameter

    .LINK
        https://wiki.server.de/display/WS/How+to+change+IPs+via+Powershell
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(ParameterSetName = "Both", Mandatory = $True)]
        [Parameter(ParameterSetName = "Dialog", Mandatory = $True)]
        [IPAddress]$DialogIP,
        [Parameter(ParameterSetName = "Both", Mandatory = $True)]
        [Parameter(ParameterSetName = "Dialog", Mandatory = $True)]
        [Int]$DialogPrefix,
        [Parameter(ParameterSetName = "Both", Mandatory = $True)]
        [Parameter(ParameterSetName = "Dialog", Mandatory = $True)]
        [IPAddress]$DialogGateway,
        [Parameter(ParameterSetName = "Both", Mandatory = $False)]
        [Parameter(ParameterSetName = "Dialog", Mandatory = $False)]
        [IPAddress]$DNS1,
        [Parameter(ParameterSetName = "Both", Mandatory = $False)]
        [Parameter(ParameterSetName = "Dialog", Mandatory = $False)]
        [IPAddress]$DNS2,
        [Parameter(ParameterSetName = "Both", Mandatory = $True)]
        [Parameter(ParameterSetName = "Backup", Mandatory = $True)]
        [IPAddress]$BackupIP,
        [Parameter(ParameterSetName = "Both", Mandatory = $True)]
        [Parameter(ParameterSetName = "Backup", Mandatory = $True)]
        [Int]$BackupPrefix,
        [Parameter(ParameterSetName = "Both", Mandatory = $True)]
        [Parameter(ParameterSetName = "Backup", Mandatory = $True)]
        [IPAddress]$BackupGateway,
        [Parameter(Mandatory = $True)]
        [ValidatePattern('(20[0-9]{9}WEB|SD[0-9]{8}|IM[0-9]{9}|C[0-9]{10}|OMM_.+|ASYS-Order-[0-9]{7}|TESTING|MIGRATION)')]
        [String]$Reason
    )

    $ErrorActionPreference = "Stop"
    $DialogError = $false
    $BackupError = $false
    $Result = @()

    if (($PSCmdlet.ParameterSetName -eq 'Dialog') -OR ($PSCmdlet.ParameterSetName -eq 'Both')) {
        $DialogIfAlias = (Get-NetAdapter -Name "*Dialog*").InterfaceAlias

        $DialogAddressFamily = (Get-NetIPAddress | Where-Object { ($_.InterfaceAlias -eq $DialogIfAlias) } ).AddressFamily
        if (($DialogAddressFamily -eq "IPv4") -AND ($DialogIP.AddressFamily -eq "InterNetwork")) {
            try {
                $OldDialogIP = (Get-NetIPAddress | Where-Object { ($_.InterfaceAlias -eq $DialogIfAlias) -AND ($_.AddressFamily -eq "IPv4") } ).IPAddress
                Remove-NetIPAddress -IPAddress $OldDialogIP -Confirm:$false
                Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $DialogIfAlias -DestinationPrefix 0.0.0.0/0 -Confirm:$false
                New-NetIPAddress -InterfaceAlias $DialogIfAlias -AddressFamily IPv4 -IPAddress $DialogIP -PrefixLength $DialogPrefix -DefaultGateway $DialogGateway
                if ($PSBoundParameters.ContainsKey("DNS1")) {
                    $DNS = ", DNS1: " + $DNS1
                    if ($PSBoundParameters.ContainsKey("DNS2")) {
                        $DNS = $DNS + ", DNS2: " + $DNS2
                    }
                    Set-DnsClientServerAddress -InterfaceAlias $DialogIfAlias -ServerAddresses $DNS1, $DNS2
                }
                $DialogMessage = "A new $DialogIfAlias IP has been set: Reason: $Reason, DialogIP: $DialogIP, DialogPrefix: $DialogPrefix, DialogGateway: $DialogGateway $DNS"
                $Result += [PSCustomObject]@{
                    'DialogReturncode' = 0
                    'DialogMessage'    = $DialogMessage
                }
                $Source = "$DialogIfAlias IP Address"
                $SourceExist = [System.Diagnostics.EventLog]::SourceExists($Source);
                if (-not $SourceExist) {
                    New-EventLog -LogName Application -Source $Source
                }
                $EventParameter = @{
                    LogName   = "Application"
                    Source    = $Source
                    EventID   = 127
                    EntryType = "Information"
                    Message   = $DialogMessage
                }
                Write-EventLog @EventParameter
            } catch {
                $ErrorMessage = $Error[0]
                $Result += [PSCustomObject]@{
                    'DialogReturncode' = 1
                    'DialogMessage'    = "Error in $DialogIfAlias IP Change: $ErrorMessage"
                }
                $DialogError = $True
            }
        } else {
            $Result += [PSCustomObject]@{
                'DialogReturncode' = 1
                'DialogMessage'    = "Only IPv4 is allowed for Dialog IP!"
            }
            $DialogError = $True
        }
    }
    if (($PSCmdlet.ParameterSetName -eq 'Backup') -OR ($PSCmdlet.ParameterSetName -eq 'Both')) {
        $BackupIfAlias = (Get-NetAdapter -Name "*Backup*").InterfaceAlias
        $BackupAddressFamily = (Get-NetIPAddress | Where-Object { ($_.InterfaceAlias -eq $BackupIfAlias) } ).AddressFamily
        if (($BackupAddressFamily -eq "IPv4") -AND ($BackupIP.AddressFamily -eq "InterNetwork")) {
            try {
                $OldBackupIP = (Get-NetIPAddress | Where-Object { ($_.InterfaceAlias -eq $BackupIfAlias) -AND ($_.AddressFamily -eq "IPv4") } ).IPAddress
                Remove-NetIPAddress -IPAddress $OldBackupIP -Confirm:$false
                New-NetIPAddress -InterfaceAlias $BackupIfAlias -AddressFamily IPv4 -IPAddress $BackupIP -PrefixLength $BackupPrefix
                Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $BackupIfAlias -DestinationPrefix 172.23.152.0/24 -Confirm:$false
                Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $BackupIfAlias -DestinationPrefix 172.23.151.0/24 -Confirm:$false
                Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $BackupIfAlias -DestinationPrefix 10.95.240.2/32 -Confirm:$false
                Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $BackupIfAlias -DestinationPrefix 10.4.232.0/24 -Confirm:$false
                New-NetRoute -AddressFamily IPv4 -InterfaceAlias $BackupIfAlias -DestinationPrefix 172.23.152.0/24 -NextHop $BackupGateway
                New-NetRoute -AddressFamily IPv4 -InterfaceAlias $BackupIfAlias -DestinationPrefix 172.23.151.0/24 -NextHop $BackupGateway
                New-NetRoute -AddressFamily IPv4 -InterfaceAlias $BackupIfAlias -DestinationPrefix 10.95.240.2/32 -NextHop $BackupGateway
                New-NetRoute -AddressFamily IPv4 -InterfaceAlias $BackupIfAlias -DestinationPrefix 10.4.232.0/24 -NextHop $BackupGateway

                $BackupMessage = "A new $BackupIfAlias IP has been set: Reason: $Reason, BackupIP: $BackupIP, BackupPrefix: $BackupPrefix, BackupGateway: $BackupGateway"
                $Result += [PSCustomObject]@{
                    'BackupReturncode' = 0
                    'BackupMessage'    = $BackupMessage
                }
                $Source = "$BackupIfAlias IP Address"
                $SourceExist = [System.Diagnostics.EventLog]::SourceExists($Source);
                if (-not $SourceExist) {
                    New-EventLog -LogName Application -Source $Source
                }
                $EventParameter = @{
                    LogName   = "Application"
                    Source    = $Source
                    EventID   = 127
                    EntryType = "Information"
                    Message   = $BackupMessage
                }
                Write-EventLog @EventParameter
            } catch {
                $ErrorMessage = $Error[0]
                $Result += [PSCustomObject]@{
                    'BackupReturncode' = 1
                    'BackupMessage'    = "Error in $BackupIfAlias IP Change: $ErrorMessage"
                }
                $BackupError = $True
            }
        } else {
            $Result += [PSCustomObject]@{
                'BackupReturncode' = 1
                'BackupMessage'    = "Only IPv4 is allowed for Backup IP!"
            }
            $BackupError = $True
        }
    }
    Start-Sleep -s 3
    if (($DialogError -ne $true) -AND ($BackupError -ne $true)) {
        $IPConfig = "C:\temp\ipconfigall.txt"
        if (Test-Path $IPConfig) {
            $DateStamp = Get-Date -UFormat "%Y-%m-%d@%H-%M-%S"
            $NewName = "ipconfigall_saved_$DateStamp.txt"
            Rename-Item $IPConfig -NewName $NewName
            Write-Verbose "Old IPConfig saved in C:\temp\$NewName"
        }
        ipconfig /all > $IPConfig
    }
    return $Result
}

### Variante 1 ###
# Aufruf der Funktion mit einzelnen Parametern:
Set-NewIpAddress -DialogIP -DialogPrefix -DialogGateway -DNS1 -DNS2 -BackupIP -BackupPrefix -BackupGateway -Reason


### Variante 2 ###
# Parameterliste für Funktionsaufruf:
$Parameter = @{
    DialogIP      =
    DialogPrefix =
    DialogGateway =
    DNS1 =
    DNS2          =
    BackupIP =
    BackupPrefix  =
    BackupGateway =
    Reason        =
}
Set-NewIpAddress @Parameter


<# To Check:
Get-NetIPConfiguration
Get-NetRoute
route print

route add 10.16.52.192 mask 255.255.255.192 10.16.52.193 -p

route change 0.0.0.0 mask 0.0.0.0 $DialogGateway
route change 172.23.152.0 mask 255.255.255.0 $BackupGateway
route change 172.23.151.0 mask 255.255.255.0 $BackupGateway
route change 10.95.240.2 mask 255.255.255.255 $BackupGateway
route change 10.4.232.0 mask 255.255.255.0 $BackupGateway
#>