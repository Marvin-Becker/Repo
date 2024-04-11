$Domain = "gt-dom1.eu-gt.net"

Get-NetAdapter | where { $_.name -eq “Ethernet” } | foreach {
    Write-Host $_.name
    Set-DnsClient $_.name -ConnectionSpecificSuffix $Domain -UseSuffixWhenRegistering $false
}
ipconfig /registerdns