Write-Host "Altes Failover Gateway:" -ForegroundColor Yellow
Get-ItemProperty -Path "HKLM:\Software\OSConfig\SCOM" -Name "FailoverGW"
Set-ItemProperty -Path "HKLM:\Software\OSConfig\SCOM" -Name "FailoverGW" -Value "exmjowvi11865.mj1dom.de"
Write-Host "Neues Failover Gateway:" -ForegroundColor Yellow
Get-ItemProperty -Path "HKLM:\Software\OSConfig\SCOM" -Name "FailoverGW"


$FailoverGW = (Get-ItemProperty -Path "HKLM:\Software\OSConfig\SCOM" -Name "FailoverGW" | Select-Object FailoverGW).FailoverGW
Test-NetConnection -ComputerName $FailoverGW -Port 5723
