
param($vm)

$pfad = "c:\vhds\"
$path = ($pfad+$VM+".vhdx")

New-VHD -Path $path -ParentPath C:\vhds\2019Master.vhdx -Differencing 

New-VM -Name $vm -MemoryStartupBytes 4GB -VHDPath $path -Generation 2 #-SwitchName "Default Switch"

Set-VM -Name $vm -ProcessorCount 2