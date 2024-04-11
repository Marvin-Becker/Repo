$ip = "10.48.34.5"
$port = "8085"
$socket = "$ip`:$port"

Set-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name AllowTelemetry -Value 0
Set-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -name DisableEnterpriseAuthProxy -value 1
Set-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -name TelemetryProxyServer -value $socket
#Set-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows Defender' -name ProxyServer -value $socket

Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name AllowTelemetry
Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -name DisableEnterpriseAuthProxy
Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -name TelemetryProxyServer
Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows Defender' -name ProxyServer
