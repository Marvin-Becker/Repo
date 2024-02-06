# einzeln ausführen

$prefix="Prefix-"

gci c:\folder1 |foreach-Object {rename-item -Path $_.FullName -NewName ($prefix+$_.Name)   }

gci c:\folder2 |foreach {rename-item -Path $_.FullName -NewName "$prefix$_.Name"  }      # $_.Name ist KEINE Variable, 

gci c:\folder3 |foreach {rename-item -Path $_.FullName -NewName "$prefix$($_.Name)"  }   # bei größerer Elementanzahl  > Endlosschleife, da neue Elemente immer wieder gelesen werden

gci c:\folder4 |% {rename-item -Path $_.FullName -NewName "$prefix$($_.Name)"  }

$dateien = gci c:\Folder5
$dateien |foreach {rename-item -Path $_.FullName -NewName ($prefix+$_.Name)   }


# Foreach-Schleife
$prefix="Prefix-"
$dateien = gci c:\Folder6

foreach($datei in $dateien)
{
$pfad = $datei.FullName
$neuername = $prefix+$datei.Name

rename-item -Path $pfad -NewName $neuername
}
