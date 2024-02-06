function Set-DefaultPrinter{
$printers = get-ciminstance win32_printer

$defprinter = $printers |where default -eq $true
$defprinterName = $defprinter.Name

$Ergebnisse = @()
$nr=1

foreach ($printer in $printers)
{
#$p = @{Name=$printer.name; def=$printer.default}
$Ergebnisse += New-Object -TypeName PSCustomObject -Property @{Nr=$nr++; Name=$($printer.name); default=$($printer.default)}
}

Write-Output -InputObject $Ergebnisse |Out-String -Stream

[int]$NewDefaultNr = read-host "Neuen Standarddrucker wählen: <Nr> ---  keine Änderung: '0'"

if($newdefaultnr -ne 0){

$NewDefaultName = $Ergebnisse |where Nr -eq $NewDefaultNr

$def = $NewDefaultName.name 
$defInst = Get-CimInstance -ClassName Win32_Printer -Filter "Name ='$def'"

Invoke-CimMethod -MethodName SetDefaultPrinter -InputObject $defInst |out-null

Write-Host "Neuer Standarddrucker:  $def" -ForegroundColor green
}
else
{
Write-Host "Keine Änderung:  Standarddrucker bleibt $defprinterName" -ForegroundColor Yellow
}
}