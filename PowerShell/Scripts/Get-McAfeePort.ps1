# Script für das Auslesen des Ports,
# um herauszufinden welches Programm dort läuft.

function Get-PortProcess {
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $LocalPorts
    )
    # Port abfragen
    foreach ($LocalPort in $LocalPorts) {
        try {
            $Connection = Get-NetTCPConnection -LocalPort $LocalPort -ErrorAction SilentlyContinue | Select-Object -First 1
            $ListenProcessID = ($Connection).OwningProcess
            $ListenProcessName = Get-Process -Id $ListenProcessID
            $ListenProcessProduct = ($ListenProcessName).Product
            $ListenProcessProductVersion = ($ListenProcessName).ProductVersion
            $ListenProcessNamePath = ($ListenProcessName).Path
            Write-Host "$env:computername;Port $LocalPort is in use;$ListenProcessProduct;$ListenProcessProductVersion;$ListenProcessNamePath;"
        } catch {
            Write-Host "$env:computername;No Process on Port $LocalPort;;;;"
        }
    }
}

Get-PortProcess -LocalPorts "8081", "8082"
