[CmdletBinding()]

param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[ValidateScript({test-path $_})]$path)

"Ergebnis: $path"

