# Action
$Body = @{
    "servername"        = "gtrynwve13447";
    "taniumPackageName" = "heapAllocation"
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/delivery/system-management/v1/action-deployment" -Method 'POST' -APIMode 'Dev' -APIType 'Delivery' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -URI "/managed-os/delivery/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Dev' -APIType 'Delivery').Content
        $Job
    } while ( $Job.Contains('Running') )
}

# Service Status
$Body = @{
    'servername'   = 'gtrynwve13447';
    'servicename'  = 'Spooler';
    'desiredServiceState' = 'Stopped'
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/delivery/system-management/v1/set-service-status" -Method 'POST' -APIMode 'Dev' -APIType 'Delivery' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -URI "/managed-os/delivery/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Dev' -APIType 'Delivery').Content
        $Job
    } while ( $Job.Contains('Running') )
}

# Software
$Body = @{
    "servername"          = "gtrynwve13447";
    "softwarePackagename" = "dotnet35";
    'orderId'             = 'ASYS-Order-0001217'
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/system-management/v1/software-deployment" -Method 'POST' -APIMode 'Dev' -APIType 'Public' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Dev' -APIType 'Public').Content
        $Job
    } while ( $Job.Contains('Running') )
}

# Share create
$Body = @{
    'servername'  = 'gtasswvw02155';
    'driveletter' = 'E';
    'sharename'   = 'Share_Test';
    'domain'      = 'asysservice.de';
    'orderId'     = 'ASYS-Order-0001217';
    'dryRun'      = $true
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/system-management/v1/filesystem-share" -Method 'POST' -APIMode 'Dev' -APIType 'Public' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Dev' -APIType 'Public').Content
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
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/system-management/v1/filesystem-share" -Method 'DELETE' -APIMode 'Dev' -APIType 'Public' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Dev' -APIType 'Public').Content
        $Job
    } while ( $Job.Contains('Running') )
}


# Server Access
$Body = @{
    'servername' = 'gtasswvw02155';
    'accessType' = 'RDP';
    'users'      = 'admin';
    'domain'     = 'asysservice.de';
    'orderId'    = 'ASYS-Order-0001217';
    'dryRun'     = $true
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/system-management/v1/user-remote-access" -Method 'POST' -APIMode 'Dev' -APIType 'Public' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Dev' -APIType 'Public').Content
        $Job
    } while ( $Job.Contains('Running') )
}

# PAM
$Body = @{
    'servername' = 'testkrisvcd001';
    'department' = 'STONAS';
    'orderId'    = 'ASYS-Order-0001217';
    'opms'       = $false;
    'dryRun'     = $true
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/" -Method 'POST' -APIMode 'Dev' -APIType 'Public' -Body $Body -Debug).Content

if ($Content) {
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os//job/$JobID" -Method "GET" -APIMode 'Dev' -APIType 'Public').Content
        $Job
    } while ( $Job.Contains('Running') )
}