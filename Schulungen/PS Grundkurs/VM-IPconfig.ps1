# IP-Konfiguration für Hyper-V Gastsysteme

$log= "c:\vhds\vmconfig.txt"
if(Test-Path $log) {Remove-Item $log}

$vms=(get-vm s*).Name |sort

$cred=Import-Clixml c:\vhds\VMCredentials.xml

$i=1
foreach ($vm in $vms){ 

$ip = "10.1.0.$i"

write "Verbinde mit $vm"

Invoke-Command -VMName $vm -ScriptBlock{New-NetIPAddress -InterfaceAlias Ethernet -IPAddress $using:ip -DefaultGateway 10.0.0.254 -PrefixLength 8 ;`Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses "10.1.0.1" } -Credential $cred 
$i++
if($?){
add-content c:\vhds\vmconfig.txt -Value "IP-Adresse $ip für VM: $vm"
}
else
{
write-host "Fehler bei VM $vm " -ForegroundColor Magenta}
}

