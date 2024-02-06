
get-vm vm* |select name, network*


get-vm vm* |select -ExpandProperty Networkadapters


New-VMSwitch -Name privat3 -SwitchType Private


Connect-VMNetworkAdapter -VMName (get-vm vm*).vmname -Name Netzwerkkarte -SwitchName private


