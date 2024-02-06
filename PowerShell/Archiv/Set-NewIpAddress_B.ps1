function Set-NewIpAddress{
	[CmdletBinding(SupportsShouldProcess = $true)]
	Param(
	[Parameter(Mandatory=$True)]
	[IPAddress]$B_IP_old,
	[Parameter(Mandatory=$True)]
	[IPAddress]$B_IP,
	[Parameter(Mandatory=$True)]
	[Int]$B_Prefix,
	[Parameter(Mandatory=$True)]
	[IPAddress]$B_Gateway
	)

$B_ifAlias="Backup"

Remove-NetIPAddress -IPAddress $B_IP_old
New-NetIPAddress -InterfaceAlias $B_ifAlias -AddressFamily IPv4 -IPAddress $B_IP -PrefixLength $B_Prefix

Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 172.23.152.0/24
Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 172.23.151.0/24
Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 10.95.240.2/32
Remove-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 10.4.232.0/24
New-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 172.23.152.0/24 -NextHop $B_Gateway
New-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 172.23.151.0/24 -NextHop $B_Gateway
New-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 10.95.240.2/32 -NextHop $B_Gateway
New-NetRoute -AddressFamily IPv4 -InterfaceAlias $B_ifAlias -DestinationPrefix 10.4.232.0/24 -NextHop $B_Gateway
}
Set-NewIpAddress -B_IP_old  -B_IP  -B_Prefix  -B_Gateway

<# To Check:
Get-NetIPConfiguration
Get-NetRoute
route print

route add 0.0.0.0 mask 0.0.0.0 $D_Gateway
route add 172.23.152.0 mask 255.255.255.0 $B_Gateway
route add 172.23.151.0 mask 255.255.255.0 $B_Gateway
route add 10.95.240.2 mask 255.255.255.255 $B_Gateway
route add 10.4.232.0 mask 255.255.255.0 $B_Gateway

route change 0.0.0.0 mask 0.0.0.0 $D_Gateway
route change 172.23.152.0 mask 255.255.255.0 $B_Gateway
route change 172.23.151.0 mask 255.255.255.0 $B_Gateway
route change 10.95.240.2 mask 255.255.255.255 $B_Gateway
route change 10.4.232.0 mask 255.255.255.0 $B_Gateway

#>
