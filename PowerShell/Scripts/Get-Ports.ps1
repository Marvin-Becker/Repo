[string[]]$Protocols = 'TCP', 'UDP'
[string[]]$Ports = '9000', '8000'


foreach ($Protocol in $Protocols) {
    foreach ($Port in $Ports) {
        try {
            $ProcessName = ((netstat -anobv | Select-String -Pattern "$Protocol(.*?)$Port" -Context 1).Context.PostContext[0]) -replace '[ \[.exe\]]'
            $ProcessProduct = (Get-Process $ProcessName).Product
            if ($ProcessProduct) {
                $Result += "Port $Port $Protocol : $ProcessProduct; "
            } else { $Result += "Port $Port $Protocol : $ProcessName; " }
        } catch {
            $Result += "No Process on Port $Port $Protocol; "
        }
    }
}
Return $Result