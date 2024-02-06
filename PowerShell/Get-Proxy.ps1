Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxySettingsPerUser
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyServer
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyOverride

Remove-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxySettingsPerUser
Remove-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyServer
Remove-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable
Remove-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyOverride
