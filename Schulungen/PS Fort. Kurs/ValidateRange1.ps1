param(
[Parameter(Mandatory=$true,HelpMessage="Du mußt hier eine Zahl eingeben!!")]
[ValidateRange(1,10)]
[int64]$z)

write $z
