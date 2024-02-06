@echo off
runas /env /user: /savecred "mmc C:\Windows\system32\dsa.msc"
exit