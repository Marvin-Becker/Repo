[CmdletBinding()]

param(
[Parameter(Mandatory=$true)]
[Validatescript({$_ -le (get-date)})]
[datetime]$p)

write $p
