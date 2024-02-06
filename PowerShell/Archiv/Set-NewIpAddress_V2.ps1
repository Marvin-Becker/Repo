function Set-NewIpAddress{
	[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    [Parameter(ParameterSetName="Both",Mandatory=$False)]
        [Parameter(ParameterSetName="Dialog",Mandatory=$False)]
        [IPAddress]$D_IP_old,
    [Parameter(ParameterSetName="Both",Mandatory=$True)]
        [Parameter(ParameterSetName="Dialog",Mandatory=$True)]
        [IPAddress]$D_IP,
    [Parameter(ParameterSetName="Both",Mandatory=$True)]
        [Parameter(ParameterSetName="Dialog",Mandatory=$True)]
        [Int]$D_Prefix,
    [Parameter(ParameterSetName="Both",Mandatory=$True)]
        [Parameter(ParameterSetName="Dialog",Mandatory=$True)]
        [IPAddress]$D_Gateway,
    [Parameter(ParameterSetName="Both",Mandatory=$False)]
        [Parameter(ParameterSetName="Dialog",Mandatory=$False)]
        [IPAddress]$D_DNS1,
    [Parameter(ParameterSetName="Both",Mandatory=$False)]
        [Parameter(ParameterSetName="Dialog",Mandatory=$False)]
        [IPAddress]$D_DNS2,
    [Parameter(ParameterSetName="Both",Mandatory=$False)]
        [Parameter(ParameterSetName="Backup",Mandatory=$False)]
        [IPAddress]$B_IP_old,
    [Parameter(ParameterSetName="Both",Mandatory=$True)]
        [Parameter(ParameterSetName="Backup",Mandatory=$True)]
        [IPAddress]$B_IP,
    [Parameter(ParameterSetName="Both",Mandatory=$True)]
        [Parameter(ParameterSetName="Backup",Mandatory=$True)]
        [Int]$B_Prefix,
    [Parameter(ParameterSetName="Both",Mandatory=$True)]
        [Parameter(ParameterSetName="Backup",Mandatory=$True)]
        [IPAddress]$B_Gateway
        )
    $ErrorActionPreference = "Stop"
    $Result = @()

    if (($PSCmdlet.ParameterSetName -eq 'Dialog') -OR ($PSCmdlet.ParameterSetName -eq 'Both')) {   
    #if ($D_IP){
        $D_ifAlias="Dialog"
        try {
            if ($PSBoundParameters.ContainsKey("D_Gateway") -AND ($PSBoundParameters.ContainsKey("D_Prefix"))){
                if ($PSBoundParameters.ContainsKey("D_IP_old")){
                    Remove-NetIPAddress -IPAddress $D_IP_old -Confirm:$false
                }
                Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $D_ifAlias -DestinationPrefix 0.0.0.0/0 -Confirm:$false
                New-NetIPAddress -InterfaceAlias $D_ifAlias -AddressFamily IPv4 -IPAddress $D_IP -PrefixLength $D_Prefix -DefaultGateway $D_Gateway
            } else {
                $Result += "Error in $D_ifAlias IP Change: Prefix and/or Gateway missing"
                $D_Err = $true
            }

            if($D_Err -ne $true){
                if ($PSBoundParameters.ContainsKey("D_DNS1")){
                    $DNS = ", D_DNS1: " + $D_DNS1 
                    if($PSBoundParameters.ContainsKey("D_DNS2")){
                        $DNS = $DNS + ", D_DNS2: " + $D_DNS2
                    }
                    Set-DnsClientServerAddress -InterfaceAlias $D_ifAlias -ServerAddresses $D_DNS1,$D_DNS2
                }
            }
            #New-NetRoute -AddressFamily IPv4 -InterfaceAlias $D_ifAlias -DestinationPrefix 0.0.0.0/0 -NextHop $D_Gateway
            

            if($D_Err -ne $true){
                $Message = "A new $D_ifAlias IP has been set: D_IP: $D_IP, D_Prefix: $D_Prefix, D_Gateway: $D_Gateway $DNS"
                $Result += $Message
                $Source = "$D_ifAlias IP Address"
                $SourceExist = [System.Diagnostics.EventLog]::SourceExists($Source);
                if (-not $SourceExist) {
                    New-Eventlog -LogName Application -Source $Source
                }

                $EventParameter = @{
                    LogName   = "Application"
                    Source    = $Source
                    EventID   = 127
                    EntryType = "Information"
                    Message   = $Message
                }
                Write-EventLog @EventParameter
            }
        } catch {
            $Result += "Error in $D_ifAlias IP Change: "
            $Result += $Error[0]
            
        }
    }

    if (($PSCmdlet.ParameterSetName -eq 'Backup') -OR ($PSCmdlet.ParameterSetName -eq 'Both')) {     
    #if($B_IP){
        $B_ifAlias="Backup"
        try {
            if ($PSBoundParameters.ContainsKey("B_Gateway") -AND ($PSBoundParameters.ContainsKey("B_Prefix"))){
                if ($PSBoundParameters.ContainsKey("B_IP_old")){
                    Remove-NetIPAddress -IPAddress $B_IP_old -Confirm:$false
                }
                New-NetIPAddress -InterfaceAlias $B_ifAlias -AddressFamily IPv4 -IPAddress $B_IP -PrefixLength $B_Prefix
                
                Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 172.23.152.0/24 -Confirm:$false
                Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 172.23.151.0/24 -Confirm:$false
                Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 10.95.240.2/32 -Confirm:$false
                Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 10.4.232.0/24 -Confirm:$false
                New-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 172.23.152.0/24 -NextHop $B_Gateway
                New-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 172.23.151.0/24 -NextHop $B_Gateway
                New-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 10.95.240.2/32 -NextHop $B_Gateway
                New-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 10.4.232.0/24 -NextHop $B_Gateway
            } else {
                $Result += "Error in $B_ifAlias IP Change: Prefix and/or Gateway missing"
                $B_Err = $true
            }

            if($B_Err -ne $true){
                $Message = "A new $B_ifAlias IP has been set: B_IP: $B_IP, B_Prefix: $B_Prefix, B_Gateway: $B_Gateway"
                $Result += $Message
                $Source = "$B_ifAlias IP Address"
                $SourceExist = [System.Diagnostics.EventLog]::SourceExists($Source);
                if (-not $SourceExist) {
                    New-Eventlog -LogName Application -Source $Source
                }

                $EventParameter = @{
                    LogName   = "Application"
                    Source    = $Source
                    EventID   = 127
                    EntryType = "Information"
                    Message   = $Message
                }
                Write-EventLog @EventParameter
            }
        } catch {
            $Result += "Error in $B_ifAlias IP Change: "
            $Result += $Error[0]
            
        }
    }
    Start-Sleep -s 3
    if(($D_Err -ne $true) -AND ($B_Err -ne $true)){
        $IPConfig = "C:\SZIR\ipconfigall.txt"
        if(Test-Path $IPConfig){
            $DateStamp = Get-Date -uformat "%Y-%m-%d@%H-%M-%S"
            $NewName = "ipconfigall_saved_$DateStamp.txt"
            Rename-Item $IPConfig -NewName $NewName
            $Result += "Old IPConfig saved in C:\SZIR\$NewName"
        }
        ipconfig /all >> $IPConfig
    }
    $Result
}
Set-NewIpAddress -D_IP_old  -D_IP  -D_Prefix  -D_Gateway  -D_DNS1  -D_DNS2  -B_IP_old  -B_IP  -B_Prefix  -B_Gateway
Set-NewIpAddress -D_IP_old 10.0.0.3 -D_IP 10.0.0.3 -D_Prefix 8 -D_Gateway 10.0.0.254 -D_DNS1 10.0.0.1 -B_IP_old 10.0.0.13 -B_IP 10.0.0.13 -B_Prefix 8 -B_Gateway 10.0.0.254
<# To Check:
Get-NetIPConfiguration
Get-NetRoute
route print

route change 0.0.0.0 mask 0.0.0.0 $D_Gateway
route change 172.23.152.0 mask 255.255.255.0 $B_Gateway
route change 172.23.151.0 mask 255.255.255.0 $B_Gateway
route change 10.95.240.2 mask 255.255.255.255 $B_Gateway
route change 10.4.232.0 mask 255.255.255.0 $B_Gateway
#>
