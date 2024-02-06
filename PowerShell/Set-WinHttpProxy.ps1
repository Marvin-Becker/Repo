$ip = ""
$port = ""
$proxy = "$ip`:$port"
$ByPassList = ""
$ByPassList += "<local>"
$ByPassList = $ByPassList -join ';'

netsh winhttp set proxy $proxy

# weitere Befehle:
netsh winhttp set proxy proxy-server= $Proxy bypass-list= $ByPassList
netsh winhttp set proxy proxy-server="192.168.2.2:8080" bypass-list="*.ourdomain.com;*.yourdomain.com*"
netsh winhttp show proxy
netsh winhttp reset proxy
netsh winhttp import proxy source =ie

# Proxy für PS Session
$proxy = 'http://'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[system.net.webrequest]::defaultwebproxy = New-Object system.net.webproxy($proxy)
[system.net.webrequest]::defaultwebproxy.credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
[system.net.webrequest]::defaultwebproxy.BypassProxyOnLocal = $true