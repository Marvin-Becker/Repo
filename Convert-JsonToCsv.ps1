#### for several json-files
# Paths
$jsonFolderPath = "C:\tmp\CommunicationStyle"
$outputCsvFile = "C:\tmp\CommunicationStyle.csv"

$csvData = @()

# Set headers for CSV
$headers = "Tenant", "Machine", "Environment", "Communication"
$csvData += $headers -join ","

# Get Content of all JSON-Files
Get-ChildItem -Path $jsonFolderPath -Filter *.json | ForEach-Object {
    # Read JSON-File and comvert into PowerShell-Object
    $jsonContent = Get-Content -Path $_.FullName -Raw | ConvertFrom-Json
    
    # Get values of keys and add to new CSV-line
    $csvLine = @()
    foreach ($key in $headers) {
        $value = $jsonContent.$key
        $csvLine += $value
    }
    
    # Add CSV-line to Data-Array
    $csvData += $csvLine -join ","
}

$csvData | Out-File -FilePath $outputCsvFile -Encoding utf8



#### for single json-file
# Paths
$jsonPath = "C:\_Work\temp\octopus.DBMS TechReports.json"
$outputCsvFile = "C:\_Work\temp\octopus.DBMS TechReports.csv"

$csvData = @()

# Set headers for CSV
$headers = "Tenant", "TimeStamp", "Data"
$csvData += $headers -join ";"

# Read JSON-File and comvert into PowerShell-Object
$jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json

# Get values of keys and add to new CSV-line
$csvLine = @()
foreach ($key in $headers) {
    $value = $jsonContent.$key
    $csvLine += $value
}

# Add CSV-line to Data-Array
$csvData += $csvLine -join ";"

$csvData | Out-File -FilePath $outputCsvFile -Encoding utf8