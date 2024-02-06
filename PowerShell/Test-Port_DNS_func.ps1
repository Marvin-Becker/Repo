function Test-TCPConnection{
param(
[parameter(Mandatory = $true,HelpMessage="Separate with ','")]
[String]$DNS
)
$Ports = "53,88,135,389,445,464,636,3268,3269"
foreach ($IP in $DNS.Split(",")){
	foreach ($port in $Ports.Split(",")){
	$TCPCon = New-Object Net.Sockets.TcpClient
	$ErrorActionPreference = 'SilentlyContinue'
	Write-Host ""
	Write-Host "Checking connection to $IP : $port" -ForegroundColor Yellow
	$connect = $TCPCon.BeginConnect($ip, $port, $null, $null)
	$wait = $connect.AsyncWaitHandle.WaitOne(5000, $false)
if (-not $wait){
	Write-Host "Port is BLOCKED." -ForegroundColor Red
	}else{
If ($TCPCon.Connected){
	Write-Host "Port is OPEN." -ForegroundColor Green
	
	$TCPCon.EndConnect($connect) | out-Null
	}else{
	Write-Host "Port is BLOCKED." -ForegroundColor Red
	
	}}
$TCPCon.Dispose | Out-Null
$TCPCon = $null | Out-Null
}}}
Test-TCPConnection #-DNS
