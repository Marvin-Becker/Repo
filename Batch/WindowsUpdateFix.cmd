@echo off
net stop wuauserv
net stop cryptsvc
net stop bits
net stop msiserver
ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
ren C:\Windows\System32\catroot2 Catroot2.old
net start wuauserv
net start cryptsvc
net start bits
net start msiserver
pause