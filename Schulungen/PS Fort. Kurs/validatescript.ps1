[CmdletBinding()]


#param([ValidateScript({test-path $_})]$path)


param([Validatescript({$_ -le (get-date)})][datetime]$date)

#write "Parametereingabe: $path "
write "Parametereingabe:  $date"
