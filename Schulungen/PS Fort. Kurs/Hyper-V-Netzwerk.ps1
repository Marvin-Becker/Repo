
get-vm S0* |select name, network*


get-vm S0* |select -ExpandProperty Networkadapters


New-VMSwitch -Name privat -SwitchType Private


Connect-VMNetworkAdapter -VMName (get-vm S0*).vmname -Name Netzwerkkarte -SwitchName privat


