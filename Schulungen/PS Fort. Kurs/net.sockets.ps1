# schneller als: Test-NetConnection www.bild.de -Port 80

function Test-Port($server, $port) {
       $client = New-Object Net.Sockets.TcpClient
       try {
           $client.Connect($server, $port)
           $true
       } catch {
           $false
       } finally {
           $client.Dispose()
       }
}

test-port www.bild.de 80