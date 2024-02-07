# POST Forward
$Content = (Invoke-WebRequest -Uri 'https://dev-api.windows.server.de/dns/v1/forward' -UseBasicParsing -UseDefaultCredentials `
        -Method "POST" -Body '{"Servername": "marvintest", "ipaddress": "10.70.24.36"}' -ContentType "application/json").content

$JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
Start-Sleep -s 10
(Invoke-WebRequest -Uri "https://dev-api.windows.server.de/job/$JobID" -UseBasicParsing -UseDefaultCredentials -Method "GET").content


# DELETE Forward
$Content = (Invoke-WebRequest -Uri 'https://dev-api.windows.server.de/dns/v1/forward' -UseBasicParsing -UseDefaultCredentials `
        -Method "DELETE" -Body '{"Servername": "marvintest", "ipaddress": "10.70.24.36"}' -ContentType "application/json").content

$JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
Start-Sleep -s 5
(Invoke-WebRequest -Uri "https://dev-api.windows.server.de/job/$JobID" -UseBasicParsing -UseDefaultCredentials -Method "GET").content


# POST Reverse
$Content = (Invoke-WebRequest -Uri 'https://dev-api.windows.server.de/dns/v1/reverse' -UseBasicParsing -UseDefaultCredentials `
        -Method "POST" -Body '{"Servername": "marvintest", "ipaddress": "10.70.24.36"}' -ContentType "application/json").content

$JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
Start-Sleep -s 5
(Invoke-WebRequest -Uri "https://dev-api.windows.server.de/job/$JobID" -UseBasicParsing -UseDefaultCredentials -Method "GET").content


# DELETE Reverse
$Content = (Invoke-WebRequest -Uri 'https://dev-api.windows.server.de/dns/v1/reverse' -UseBasicParsing -UseDefaultCredentials `
        -Method "DELETE" -Body '{"Servername": "marvintest", "ipaddress": "10.70.24.36"}' -ContentType "application/json").content

$JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
Start-Sleep -s 5
(Invoke-WebRequest -Uri "https://dev-api.windows.server.de/job/$JobID" -UseBasicParsing -UseDefaultCredentials -Method "GET").content
