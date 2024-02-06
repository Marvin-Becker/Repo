$Result = ""
[string]$Server = $env:COMPUTERNAME
$Result += $Server + ";"
[string]$Domain = (Get-CimInstance win32_computersystem).Domain
$Result += $Domain + ";"
[string[]]$DialogIP = (Get-NetIPAddress | Where-Object { (($_.InterfaceAlias -Like "Dialog*" -AND $_.AddressFamily -eq "IPv4")) -OR (($_.InterfaceAlias -Like "Ethernet*" -AND $_.AddressFamily -eq "IPv4")) } ).IPAddress
[string]$DialogIP = $DialogIP -join ','
$Result += $DialogIP + ";"
[string]$OSName = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
($OSName | Select-String -Pattern 'Windows' -Context 0) -match "[0-9]{4}" > $NULL
[string]$OSVersion = $Matches.Values
$Result += $OSVersion + ";"

Return $Result