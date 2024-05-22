#Get Current Path
$Environment = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

#Remove Item from Path
$RemoveItem = 'C:\Program Files\OpenSSL-Win64\bin'
foreach ($path in ($Environment).Split(";")) {
    if ($path -like "*$RemoveItem*") {
        $Environment = $Environment.Replace($Path , "")
    }
}

#Add Items to Environment
$AddItem = ';' + 'C:\Program Files\OpenSSL-Win64\bin'
$Environment = $Environment.Insert($Environment.Length, $AddItem)

#Set Updated Path
[System.Environment]::SetEnvironmentVariable("Path", $Environment, "Machine")


# Simple setting variable
$variable = 'MongoConnectionString' #'VariableName'
$value = 'mongodb://becker:aaFS34$@deseau01:27017/?tls=true' #'VariableValue'
$scope = 'User'

#Get Current Path
$Environment = [System.Environment]::GetEnvironmentVariable($variable, $scope)

# Set variable 
if ($Environment -contains $value) {
    Write-Output 'Wanted value already set'
} elseif ($Environment) {
    Write-Output 'There is already a different value'
    $Environment
} else {
    [System.Environment]::SetEnvironmentVariable($variable, $value, $scope)
}