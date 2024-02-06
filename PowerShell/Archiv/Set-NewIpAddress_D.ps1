function Set-NewIpAddress{
	[CmdletBinding(SupportsShouldProcess = $true)]
	Param(
	[Parameter(Mandatory=$True)]
	[IPAddress]$D_IP_old,
	[Parameter(Mandatory=$True)]
	[IPAddress]$D_IP,
	[Parameter(Mandatory=$True)]
	[Int]$D_Prefix,
	[Parameter(Mandatory=$True)]
	[IPAddress]$D_Gateway,
	[Parameter(Mandatory=$True)]
	[IPAddress]$D_DNS1,
	[Parameter(Mandatory=$True)]
	[IPAddress]$D_DNS2
	)

$D_ifAlias="Dialog"

Remove-NetIPAddress -IPAddress $D_IP_old -Confirm:$false
New-NetIPAddress -InterfaceAlias $D_ifAlias -AddressFamily IPv4 -IPAddress $D_IP -PrefixLength $D_Prefix -DefaultGateway $D_Gateway
Set-DnsClientServerAddress -InterfaceAlias $D_ifAlias -ServerAddresses $D_DNS1,$D_DNS2

Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $D_ifAlias -DestinationPrefix 0.0.0.0/0 -Confirm:$false
New-NetRoute -AddressFamily IPv4 -InterfaceAlias $D_ifAlias -DestinationPrefix 0.0.0.0/0 -NextHop $D_Gateway

}
Set-NewIpAddress -D_IP_old  -D_IP  -D_Prefix  -D_Gateway  -D_DNS1  -D_DNS2

<# To Check:
Get-NetIPConfiguration
Get-NetRoute
route print

route change 0.0.0.0 mask 0.0.0.0 $D_Gateway
#>
