# Action Deployment
$Body = @{
    "servername"        = "gtrynwve13447";
    "taniumPackageName" = "heapAllocation"
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/delivery/system-management/v1/action-deployment" -Method 'POST' -APIMode 'Dev' -APIType 'Delivery' -Body $Body -Debug).Content | ConvertFrom-Json 
$JobID = $Content.jobId
if ($Content) {
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -URI "/managed-os/delivery/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Dev' -APIType 'Delivery' -Debug).Content | ConvertFrom-Json
    } while ( $Job.jobStatusName -eq 'Running' )
}

# Service Status
$Body = @{
    'servername'          = 'gtrynwve13447';
    'servicename'         = 'Spooler';
    'desiredServiceState' = 'Stopped'
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/delivery/system-management/v1/set-service-status" -Method 'POST' -APIMode 'Dev' -APIType 'Delivery' -Body $Body -Debug).Content | ConvertFrom-Json
$JobID = $Content.jobId
if ($Content) {
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -URI "/managed-os/delivery/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Dev' -APIType 'Delivery' -Debug).Content | ConvertFrom-Json
    } while ( $Job.jobStatusName -eq 'Running' )
}

# Software Deployment
$Body = @{
    "servername"          = "gtrynwve13447";
    "softwarePackagename" = "dotnet35";
    'orderId'             = 'ASYS-Order-0001217'
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/system-management/v1/software-deployment" -Method 'POST' -APIMode 'Dev' -APIType 'Public' -Body $Body -Debug).Content | ConvertFrom-Json
$JobID = $Content.jobId
if ($Content) {
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Dev' -APIType 'Public' -Debug).Content | ConvertFrom-Json
    } while ( $Job.jobStatusName -eq 'Running' )
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
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/system-management/v1/filesystem-share" -Method 'POST' -APIMode 'Prod' -APIType 'Public' -Body $Body -Debug).Content | ConvertFrom-Json
$JobID = $Content.jobId
if ($Content) {
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Prod' -APIType 'Public' -Debug).Content | ConvertFrom-Json
    } while ( $Job.jobStatusName -eq 'Running' )
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
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/system-management/v1/filesystem-share" -Method 'DELETE' -APIMode 'Prod' -APIType 'Public' -Body $Body -Debug).Content | ConvertFrom-Json
$JobID = $Content.jobId
if ($Content) {
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Prod' -APIType 'Public' -Debug).Content | ConvertFrom-Json
    } while ( $Job.jobStatusName -eq 'Running' )
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
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/system-management/v1/user-remote-access" -Method 'POST' -APIMode 'Prod' -APIType 'Public' -Body $Body -Debug).Content | ConvertFrom-Json
$JobID = $Content.jobId
if ($Content) {
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os/system-management/v1/job/$JobID" -Method "GET" -APIMode 'Prod' -APIType 'Public' -Debug).Content | ConvertFrom-Json
    } while ( $Job.jobStatusName -eq 'Running' )
}

# PAM
$Body = @{
    'servername' = 'gtasswvw02155';
    'department' = 'STONAS';
    'orderId'    = 'ASYS-Order-0001217';
    'opms'       = $false;
    'dryRun'     = $true
}
$Body = $Body | ConvertTo-Json
$Content = (Invoke-SDMSAPIRequest -URI "/managed-os/internal/pam-management/v1/preparations/department/windows/provision" -Method 'POST' -APIMode 'Prod' -APIType 'Public' -Body $Body -Debug).Content | ConvertFrom-Json
$JobID = $Content.jobId
if ($Content) {
    do {
        Start-Sleep 10
        $Job = (Invoke-SDMSAPIRequest -Uri "/managed-os//job/$JobID" -Method "GET" -APIMode 'Prod' -APIType 'Public' -Debug).Content | ConvertFrom-Json
    } while ( $Job.jobStatusName -eq 'Running' )
}