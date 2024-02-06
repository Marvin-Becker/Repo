 # Kein Script
 # Zeilen einzeln markieren und mit F8 ausführen


# normale Ausgabe, selbst gebaut
Get-Process c* |select Name, @{Label="CPU(s)"; Expression={$_.cpu}}

# Zahlen als Sting formatiert
Get-Process c* |select Name, @{L="CPU(s)"; E={"{0:N2}" -f $_.cpu}}

# Zahlen gerundet
Get-Process c* |select Name, @{L="CPU(s)";E={[math]::round($_.cpu,2)}}


Get-Process c* |ft @{L="Neu"; E={$_.Name}; w=25}, @{Label="CPU(s)"; Expression={"{0:N2}" -f $_.cpu}; align="right"; width=15}


