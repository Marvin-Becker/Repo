Write-Host "Altes Failover Gateway:" -ForegroundColor Yellow
Get-ItemProperty -Path "HKLM:\Software\Arvato\OSConfig\SCOM" -Name "FailoverGW"
Set-ItemProperty -Path "HKLM:\Software\Arvato\OSConfig\SCOM" -Name "FailoverGW" -value "exmjowvi11865.mj1dom.de"
Write-Host "Neues Failover Gateway:" -ForegroundColor Yellow
Get-ItemProperty -Path "HKLM:\Software\Arvato\OSConfig\SCOM" -Name "FailoverGW"


$FailoverGW = (Get-ItemProperty -Path "HKLM:\Software\Arvato\OSConfig\SCOM" -Name "FailoverGW" | Select-Object FailoverGW).FailoverGW
Test-NetConnection -computername $FailoverGW -port 5723
