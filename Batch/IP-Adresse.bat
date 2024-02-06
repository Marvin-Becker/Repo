@echo off  
for /f "tokens=2 delims=[]" %%a in ('ping -n 1 -4 %COMPUTERNAME% ^| find /I "%COMPUTERNAME%"') do @echo %%a 
pause