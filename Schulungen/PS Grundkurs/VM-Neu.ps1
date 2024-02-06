
param($vm)
$pfad = "c:\vhds\"
$path = ($pfad+$VM+".vhdx")

New-VHD -Path $path -ParentPath C:\vhds\2019Master.vhdx -Differencing 

New-VM -Name $vm -MemoryStartupBytes 4GB -VHDPath $path -SwitchName "Default Switch" -Generation 2

Set-VM -Name $vm -ProcessorCount 2