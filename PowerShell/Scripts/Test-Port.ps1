function Test-TCPConnection {
param
(
[parameter(Mandatory = $true)]
[String]$ips,
[String]$ports
)

foreach ($ip in $ips.Split(",")){
	foreach ($port in $ports.Split(",")){
$TCPCon = New-Object System.Net.Sockets.TcpClient
$ErrorActionPreference = 'SilentlyContinue'
Write-Host ""
Write-Host "Checking connection to $ip : $port" -ForegroundColor Yellow
$connect = $TCPCon.BeginConnect($ip, $port, $null, $null)
$wait = $connect.AsyncWaitHandle.WaitOne(5000, $false)
if (-not $wait){
    Write-Host "$ip : Port $port is BLOCKED." -ForegroundColor Red
    } else {
if ($TCPCon.Connected) {
     Write-Host "$ip : Port $port is OPEN." -ForegroundColor Green
     $TCPCon.EndConnect($connect)
     } else {
     Write-Host "$ip : Port $port is BLOCKED." -ForegroundColor Red
     }
    }
$TCPCon.Dispose | Out-Null
$TCPCon = $null | Out-Null
}}}
Test-TCPConnection -ips "10.48.34.5" -ports "8085" #5723 #SCOM-Port

#####################################
### Für einzelne Server und Ports ###

Test-NetConnection -computername  -port
(Test-NetConnection -computername "10.48.34.5" -port "8085").TcpTestSucceeded

SCOM-Gateways [5723]:
$FailoverGW = (Get-ItemProperty -Path "HKLM:\Software\OSConfig\SCOM" -Name "FailoverGW" | Select-Object FailoverGW).FailoverGW
Test-NetConnection -computername $FailoverGW -port 5723

BGROUP = "10.205.5.143,10.205.5.142"
RENK = "gtrenwvi00503,GTRENWVN00924"
DE = "gtalfwvm01287"

