#  kein Script!!!  Zeilen einzeln markieren und ausführen.

New-Item -path HKLM:\SOFTWARE -Name Thomas

New-ItemProperty -Path HKLM:\SOFTWARE\Thomas -Name "(default)" -Value "Test"
New-ItemProperty -Path HKLM:\SOFTWARE\Thomas -Name Wert2 -Value 55
New-ItemProperty -Path HKLM:\SOFTWARE\Thomas -Name Wert3 -Value 99 -PropertyType Dword

Get-ItemProperty -Path HKLM:\SOFTWARE\Thomas
(Get-ItemProperty -Path HKLM:\SOFTWARE\Thomas).wert2
Get-ItemProperty -Path HKLM:\SOFTWARE\Thomas |Select-Object -ExpandProperty wert3

Remove-ItemProperty -Name wert1 -Path HKLM:\SOFTWARE\Thomas

Get-Item HKLM:\SOFTWARE\test 

Get-Item HKLM:\SOFTWARE\ullmann 
Remove-Item HKLM:\SOFTWARE\ullmann 