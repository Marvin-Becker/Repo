function New-WebRequest () {
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [parameter(Mandatory = $true)]
        [ValidatePattern('^[a-zA-Z0-9\-]{1,15}$')]
        [string]
        $Servername,
        [parameter(Mandatory = $true)]
        [ValidateSet('PAM', 'Disk', 'FNT', 'DNSforward', 'DNSreverse', 'Share', 'Access')]
        [String]
        $Repo,
        [Parameter(Mandatory = $true)]
        [ValidateSet('POST', 'PUT', 'GET', 'DELETE')]
        [String]
        $Method,
        [parameter(Mandatory = $false)]
        [boolean]
        $DryRun = $true
    )

    $OrderID = 'ASYS-Order-0001217'

    switch ($Repo) {
        'PAM' { $Path = 'access-management/v1/department' }
        'Disk' { $Path = 'disk-management/v1/disk' }
        'FNT' { $Path = 'fnt-net/v1/ipAddress' }
        'DNSforward' { $Path = 'dns/v1/forward' }
        'DNSreverse' { $Path = 'dns/v1/reverse' }
        'Share' { $Path = 'system-management/v1/share' }
        'Access' { $Path = 'system-management/v1/access' }
    }

    function Get-JobStatus {
        [CmdletBinding()]
        [OutputType([String])]
        param (
            [Parameter(Mandatory = $true)]
            [String]
            $JobID
        )

        do {
            Start-Sleep 10
            $Status = (Invoke-WebRequest -Uri "https://dev-api.windows.arvato-systems.de/job/$JobID" -UseBasicParsing -UseDefaultCredentials `
                    -Method "GET" -Verbose).Content
        } while ( $Status.Contains('Running') )
        #$Status = '{ "jobOutput": {}, "jobError":"", "jobStatusName":"Failed", "jobStatus":3}'
        Write-Output $Status
    }

    if ($Repo -eq 'PAM') {
        $Body = @{
            'servername' = 'gtasswvw02155';
            'department' = 'STONAS';
            'orderId'    = 'ASYS-Order-0001217';
            'opms'       = $false;
            'dryRun'     = $true
        }
    }

    if ($Repo -eq 'Disk') {
        switch ($Method) {
            'POST' {
                $Body = @{
                    'Servername'     = $Servername;
                    'driveletter'    = 'M';
                    'diskType'       = 'gp3';
                    'size'           = '5';
                    'filesystemMode' = 'Customer Filesystem';
                    'monitored'      = $false;
                    'orderId'        = $OrderID;
                    'dryRun'         = $DryRun
                }
            }
            'PUT' {
                $Body = @{
                    'Servername'  = $Servername;
                    'Driveletter' = 'M';
                    'Size'        = '10';
                    'OrderID'     = $OrderID;
                    'dryRun'      = $DryRun
                }
            }
            'DELETE' {
                $Body = @{
                    'Servername'  = $Servername;
                    'Driveletter' = 'M';
                    'OrderID'     = $OrderID;
                    'dryRun'      = $DryRun
                }
            }
        }
    }

    if ($Repo -eq 'Share') {
        $Body = @{
            'servername'  = $Servername;
            'driveletter' = 'E';
            'sharename'   = 'ShareTest';
            'domain'      = 'asysservice.de';
            'orderId'     = $OrderID;
            'dryRun'      = $DryRun
        }
    }

    if ($Repo -eq 'Access') {
        $Body = @{
            'servername' = $Servername;
            'access'     = 'RDP';
            'users'      = 'admkris085';
            'domain'     = 'asysservice.de';
            'orderId'    = $OrderID;
            'dryRun'     = $DryRun
        }
    }

    if ($Repo -eq 'DNSforward') {
        $Body = @{
            'servername' = $Servername;
            'ipAddress'  = '10.70.24.36';
            'timeToLive' = 86400;
            'orderId'    = $OrderID;
            'dryRun'     = $DryRun
        }
    }

    $Body = $Body | ConvertTo-Json
    $Body
    $Path
    $Content = (Invoke-WebRequest -Uri "https://dev-api.windows.arvato-systems.de/$Path" -UseBasicParsing -UseDefaultCredentials `
            -Method $Method -Body $Body -ContentType "application/json").Content
    
    if ($Content) {
        $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
        Get-JobStatus -JobID $JobID
    }
}

New-WebRequest -Servername "kris085" -Repo "DNSforward" -Method "POST" -DryRun $true


####################################################
# FileTransfer
$Body = @{
    'SourceAgent'       = 'GTASSWVF05934';
    'SourceFileName'    = 'C:\temp\Test.txt';
    'TargetAgent'       = 'gtasswvc08661';
    'TargetDir'         = 'C:\temp';
    'TargetFileName'    = 'Test.txt';
    'OverwriteIfExists' = $true;
    'CorrelationID'     = 'GTASSWVF05934';
    'Timeout'           = '300';
    'APIMode'           = 'Prod'
}
Invoke-StreamworksAdHocFileTransfer @Body -Debug

# Service Status
$Body = @{
    'servername'   = 'gtrynwve13447';
    'servicename'  = 'Spooler';
    'desiredState' = 'Stopped'
}
$Body = $Body | ConvertTo-Json
$Path = 'system-management/v1/servicestatus'
$Content = (Invoke-WebRequest -Uri "https://dev-api.windows.arvato-systems.de/$Path" -UseBasicParsing -UseDefaultCredentials -Method 'POST' -Body $Body -ContentType "application/json").Content

if ($Content) {
    do {
        Start-Sleep 10
        $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
        $Job = (Invoke-WebRequest -UseDefaultCredentials -Method "GET" -Uri "https://dev-api.windows.arvato-systems.de/job/$JobID").Content
        $Job
    } while ( $Job.Contains('Running') )
}

## PAM
$Body = @{
    'servername' = 'testkrisvcd001';
    'department' = 'STONAS';
    'orderId'    = 'ASYS-Order-0001217';
    'opms'       = $false;
    'dryRun'     = $true
}

## Share
$Body = @{
    'servername'  = 'gtasswvw02155';
    'driveletter' = 'E';
    'sharename'   = 'ShareTest';
    'domain'      = 'asysservice.de';
    'orderId'     = 'ASYS-Order-0001217';
    'dryRun'      = $true
}

## Access
$Body = @{
    'servername' = 'testkrisvcd001';
    'access'     = 'RDP';
    'users'      = 'admkris085';
    'domain'     = 'asysservice.de';
    'orderId'    = 'ASYS-Order-0001217';
    'dryRun'     = $true
}

$Body = $Body | ConvertTo-Json
#$Path = 'system-management/v1/share'
$Path = 'system-management/v1/access'
#$Path = '/access-management/v1/department'
$Content = (Invoke-WebRequest -Uri "https://dev-api.windows.arvato-systems.de/$Path" -UseBasicParsing -UseDefaultCredentials -Method 'POST' -Body $Body -ContentType "application/json").Content

if ($Content) {
    do {
        Start-Sleep 10
        $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
        $Job = (Invoke-WebRequest -UseDefaultCredentials -Method "GET" -Uri "https://dev-api.windows.arvato-systems.de/job/$JobID").Content
        $Job
    } while ( $Job.Contains('Running') )
}

#### Disk ####
### CREATE
$Body = @{
    'servername'     = 'exlocwvu08367';
    'driveletter'    = 'G';
    'diskType'       = 'gp3';
    'size'           = 4;
    'filesystemMode' = 'Customer Filesystem';
    'monitored'      = $false;
    'orderId'        = 'ASYS-Order-0001217';
    'dryRun'         = $true
}
$Body = $Body | ConvertTo-Json
$Job = Invoke-WebRequest -Uri "https://dev-api.windows.arvato-systems.de/disk-management/v1/disk" -UseBasicParsing -UseDefaultCredentials -Method "POST" -Body $Body -ContentType "application/json"
Start-Sleep 2
(Invoke-WebRequest -UseDefaultCredentials -Method "GET" -Uri "https://dev-api.windows.arvato-systems.de/job/$(($Job.Content | ConvertFrom-Json).jobId)").Content

### UPDATE
$Body = @{
    'servername'  = 'exlocwvu08367';
    'driveletter' = 'G';
    'size'        = 8;
    'orderId'     = 'ASYS-Order-0001217';
    'dryRun'      = $true
}
$Body = $Body | ConvertTo-Json
$Job = Invoke-WebRequest -Uri "https://dev-api.windows.arvato-systems.de/disk-management/v1/disk" -UseBasicParsing -UseDefaultCredentials -Method "PUT" -Body $Body -ContentType "application/json"
Start-Sleep 2
(Invoke-WebRequest -UseDefaultCredentials -Method "GET" -Uri "https://dev-api.windows.arvato-systems.de/job/$(($Job.Content | ConvertFrom-Json).jobId)").Content

### DELETE
$Body = @{
    'servername'  = 'exlocwvu08367';
    'driveletter' = 'G';
    'orderId'     = 'ASYS-Order-0001217';
    'dryRun'      = $true
}
$Body = $Body | ConvertTo-Json
$Job = Invoke-WebRequest -Uri "https://dev-api.windows.arvato-systems.de/disk-management/v1/disk" -UseBasicParsing -UseDefaultCredentials -Method "DELETE" -Body $Body -ContentType "application/json"
Start-Sleep 2
(Invoke-WebRequest -UseDefaultCredentials -Method "GET" -Uri "https://dev-api.windows.arvato-systems.de/job/$(($Job.Content | ConvertFrom-Json).jobId)").Content