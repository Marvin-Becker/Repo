## Action
$Body = @{
    "servername"        = "gtasswvw02155";
    "taniumPackageName" = "heapAllocation"
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/delivery/system-management/v1/action-deployment" -Method 'POST' -APIMode 'Prod' -APIType 'Delivery' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -URI "/managed-os/delivery/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Prod' -APIType 'Delivery').Content
        $Job
    } while ( $Job.Contains('Running') )
}

# Service Status
$Body = @{
    'servername'          = 'gtasswvw02155';
    'servicename'         = 'Spooler';
    'desiredServiceState' = 'Stopped'
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/delivery/system-management/v1/set-service-status" -Method 'POST' -APIMode 'Prod' -APIType 'Delivery' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -URI "/managed-os/delivery/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Prod' -APIType 'Delivery').Content
        $Job
    } while ( $Job.Contains('Running') )
}

# Software
$Body = @{
    "servername"          = "gtasswvw02155";
    "softwarePackagename" = "dotnet35";
    'orderId'             = 'ASYS-Order-0000123'
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/system-management/v1/software-deployment" -Method 'POST' -APIMode 'Prod' -APIType 'Public' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Prod' -APIType 'Public').Content
        $Job
    } while ( $Job.Contains('Running') )
}

# Share
$Body = @{
    'servername'  = 'gtasswvw02155';
    'driveletter' = 'E';
    'sharename'   = 'Share_Test!';
    'domain'      = 'asysservice.de'
    'orderId'     = 'ASYS-Order-0000123';
    'dryRun'      = $true
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/system-management/v1/filesystem-share" -Method 'POST' -APIMode 'Prod' -APIType 'Public' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Prod' -APIType 'Public').Content
        $Job
    } while ( $Job.Contains('Running') )
}

# Share remove
$Body = @{
    'servername'   = 'gtasswvw02155';
    'driveletter'  = 'E';
    'sharename'    = 'Share_Test';
    'domain'       = 'asysservice.de';
    'deleteFolder' = $true;
    'orderId'      = 'ASYS-Order-0001217';
    'dryRun'       = $true
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/system-management/v1/filesystem-share" -Method 'DELETE' -APIMode 'Prod' -APIType 'Public' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Prod' -APIType 'Public').Content
        $Job
    } while ( $Job.Contains('Running') )
}

# Access
$Body = @{
    'servername' = 'gtrynwve13447';
    'accessType' = 'RDP';
    'users'      = 'admin';
    'domain'     = 'asysservice.de';
    'orderId'    = 'ASYS-Order-0000123';
    'dryRun'     = $true
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/system-management/v1/user-remote-access" -Method 'POST' -APIMode 'Prod' -APIType 'Public' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Prod' -APIType 'Public').Content
        $Job
    } while ( $Job.Contains('Running') )
}
