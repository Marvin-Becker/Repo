# prüft, ob optionaler Parameter vorhanden ist und verzweigt dann

function test {
param($test1, $test2)

if ($PSBoundParameters.ContainsKey("test1"))
{
get-service $test1
}
else
{get-service 
#exit
}
}
test #-test1 "spooler" 

