[array]$computer = @("degtlun5833","csgpnek1")
[array]$domain = @("server.arvato-systems.de")

foreach ($server in $computer){
    if($PSBoundParameters.ContainsKey('domain')){
      $fqdn = "$server.$domain"
    }else{
        $fqdn = "$server"
    }
    Resolve-DnsName $fqdn
}
