function Test-TCPConnection {
$ips = "145.228.56.39,145.228.56.69,145.228.56.70,145.228.56.71,145.228.56.72" # Reverse "30000,30001,50000"
$ports = "9600"

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
Test-TCPConnection


Test-NetConnection -ComputerName sw-ps-prod.server.server.de -Port 9600
