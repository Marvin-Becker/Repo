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
	[IPAddress]$D_DNS2,
	[Parameter(Mandatory=$True)]
	[IPAddress]$B_IP_old,
	[Parameter(Mandatory=$True)]
	[IPAddress]$B_IP,
	[Parameter(Mandatory=$True)]
	[Int]$B_Prefix,
	[Parameter(Mandatory=$True)]
	[IPAddress]$B_Gateway
	)

$D_ifAlias="Dialog"
$B_ifAlias="Backup"

Remove-NetIPAddress -IPAddress $D_IP_old -Confirm:$false
New-NetIPAddress -InterfaceAlias $D_ifAlias -AddressFamily IPv4 -IPAddress $D_IP -PrefixLength $D_Prefix -DefaultGateway $D_Gateway
Set-DnsClientServerAddress -InterfaceAlias $D_ifAlias -ServerAddresses $D_DNS1,$D_DNS2
Remove-NetIPAddress -IPAddress $B_IP_old -Confirm:$false
New-NetIPAddress -InterfaceAlias $B_ifAlias -AddressFamily IPv4 -IPAddress $B_IP -PrefixLength $B_Prefix

Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $D_ifAlias -DestinationPrefix 0.0.0.0/0 -Confirm:$false
New-NetRoute -AddressFamily IPv4 -InterfaceAlias $D_ifAlias -DestinationPrefix 0.0.0.0/0 -NextHop $D_Gateway

Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 172.23.152.0/24
Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 172.23.151.0/24
Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 10.95.240.2/32
Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 10.4.232.0/24
New-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 172.23.152.0/24 -NextHop $B_Gateway
New-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 172.23.151.0/24 -NextHop $B_Gateway
New-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 10.95.240.2/32 -NextHop $B_Gateway
New-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 10.4.232.0/24 -NextHop $B_Gateway
}
Set-NewIpAddress -D_IP_old  -D_IP  -D_Prefix  -D_Gateway  -D_DNS1  -D_DNS2  -B_IP_old  -B_IP  -B_Prefix  -B_Gateway

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
