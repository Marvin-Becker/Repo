$dialogNIC = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetConnectionID -like "*Dialog*" }
$DNS = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.InterfaceIndex -eq $dialogNIC.InterfaceIndex }
$domainPorts = "53,88,135,389,445,464,636,3268,3269"

function Test-TCPConnection {
    param(
        [parameter(Mandatory = $true)]
        [String]$targetIPs,
        [String]$targetPorts
    )
    foreach ($IP in $targetIPs.Split(",")) {
        foreach ($port in $targetPorts.Split(",")) {
            $TCPCon = New-Object Net.Sockets.TcpClient
            $ErrorActionPreference = 'SilentlyContinue'
            Write-Host ""
            Write-Host "Checking connection to $IP : $port" -ForegroundColor Yellow
            $connect = $TCPCon.BeginConnect($ip, $port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne(5000, $false)
            if (-not $wait) {
                Write-Host "Port is BLOCKED." -ForegroundColor Red
            } else {
                If ($TCPCon.Connected) {
                    Write-Host "Port is OPEN." -ForegroundColor Green
                    $TCPCon.EndConnect($connect) | Out-Null
                } else {
                    Write-Host "Port is BLOCKED." -ForegroundColor Red
                }
            }
            $TCPCon.Dispose | Out-Null
            $TCPCon = $null | Out-Null
        }
    }
}

foreach ($DNSIP in $DNS.DNSServerSearchOrder) {
    "" 
    Write-Host "Checking connection to primary / secondary DNS servers ..." -ForegroundColor Yellow
    Test-TCPConnection -targetIPs $DNSIP -targetPorts $domainPorts
}
