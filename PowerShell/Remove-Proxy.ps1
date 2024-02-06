Remove-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxySettingsPerUser
Remove-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name AutoConfigURL
Remove-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyServer
Remove-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable
Remove-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyOverride
Remove-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -name DisableEnterpriseAuthProxy
Remove-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -name TelemetryProxyServer
Remove-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows Defender' -name ProxyServer

Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxySettingsPerUser
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name AutoConfigURL
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyServer
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyOverride
Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -name DisableEnterpriseAuthProxy
Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -name TelemetryProxyServer
Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows Defender' -name ProxyServer
