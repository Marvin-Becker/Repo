 # Kein Script
 # Zeilen einzeln markieren und mit F8 ausführen

Get-Process i* |select Name,@{Label="CPU(s)";Expression={$_.cpu}}

Get-Process i* |select Name,@{L="CPU(s)";E={"{0:N2}" -f $_.cpu}}

Get-Process i* |select Name,@{L="CPU(s)";E={[math]::round($_.cpu,2)}}

Get-Process i* |ft @{L="Neu";E={$_.Name};width=25},@{L="CPU(s)";E={"{0:N2}" -f $_.cpu};align="right";width=15}


