$vm=read-host "Welcher VM sollen virtuelle Laufwerke hinzugefügt werden?"
$anzahl= read-host "Anzahl zusätzlicher Festplatten?"
$pfad = "c:\vhds\"

for ($a=1; $a -le $anzahl; $a++)
{
$vhdpfad =$pfad+$vm+"0$a"+".vhdx"

New-VHD -Path $vhdpfad -Dynamic -SizeBytes 50GB

Add-VMHardDiskDrive -VMName $vm -Path $vhdpfad -ControllerType SCSI 
}