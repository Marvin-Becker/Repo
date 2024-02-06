<# Begin .. Process .. End
kommt immer dann zum Einsatz, wenn ein Array an eine Funktion übergeben 
und in einer Foreach-Schleife abgearbeitet wird.
Process ist Pflicht, Begin und End sind optional (s.u.)

Hier geht es um eine Pipelineverarbeitung.
Das Script verhält sich anders!
Jegliches "Drumherum" muß in Begin{} bzw End{} gepackt werden
#>

function test{
[CmdletBinding()]
param(
[parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)][char[]] $driveletter)

begin  # wird nur einmal ausgeführt
{
"Start"}

process 
{
foreach($l in $driveletter)
{
write-verbose $l
Get-Volume $l}
}

end  # wird nur einmal ausgeführt
{"Ende"}
}


#"c","f" | test 

Get-Volume |where Driveletter -ne $null  |test