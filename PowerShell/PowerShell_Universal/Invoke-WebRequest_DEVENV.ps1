# Software
$Body = @{
    'servername'          = 'gtrynwve13447';
    'softwarePackagename' = 'dotnet35';
    'orderId'             = 'ASYS-Order-0001217'
} | ConvertTo-Json
$Path = 'tanium/v1/softwaredeployment'
$Content = (Invoke-WebRequest -Uri "https://localhost:5000/$Path" -UseBasicParsing -UseDefaultCredentials -Method 'DELETE' -Body $Body -ContentType "application/json").Content

if ($Content) {
    do {
        Start-Sleep 10
        $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
        $Job = (Invoke-WebRequest -UseDefaultCredentials -Method "GET" -Uri "https://localhost:5000/job/$JobID").Content
        $Job
    } while ( $Job.Contains('Running') )
}