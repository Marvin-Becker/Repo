$params = @{Name  = "PowerShell Universal"
    DisplayName   = "PowerShell Universal" 
    Description   = "Allow PowerShell Universal"
    Profile       = 'Any' 
    Direction     = 'Inbound' 
    Action        = 'Allow' 
    Protocol      = 'TCP'
    Program       = 'D:\PowerShellUniversal\Universal.Server.exe'
    Service       = 'PowerShellUniversal'
    LocalAddress  = 'Any'
    LocalPort     = 5000 
    RemoteAddress = 'Any'
}
    
New-NetFirewallRule @params

$params = @{Name  = "PowerShell Universal HTTPS"
    DisplayName   = "PowerShell Universal HTTPS" 
    Description   = "Allow PowerShell Universal HTTPS"
    Profile       = 'Any' 
    Direction     = 'Inbound' 
    Action        = 'Allow' 
    Protocol      = 'TCP'
    Program       = 'D:\PowerShellUniversal\Universal.Server.exe'
    Service       = 'PowerShellUniversal'
    LocalAddress  = 'Any'
    LocalPort     = 443 
    RemoteAddress = '10.242.2.52/24'
}
    
New-NetFirewallRule @params

$params = @{Name  = "PowerShell Universal HTTPS:5001"
    DisplayName   = "PowerShell Universal HTTPS:5001" 
    Description   = "Allow PowerShell Universal HTTPS on Port 5001"
    Profile       = 'Any' 
    Direction     = 'Inbound' 
    Action        = 'Allow' 
    Protocol      = 'TCP'
    Program       = 'D:\PowerShellUniversal\Universal.Server.exe'
    Service       = 'PowerShellUniversal'
    LocalAddress  = 'Any'
    LocalPort     = 5001 
    RemoteAddress = '10.242.2.52/24'
}
    
New-NetFirewallRule @params