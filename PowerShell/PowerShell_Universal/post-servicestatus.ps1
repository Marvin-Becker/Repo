<#
.SYNOPSIS
Trigger a new action deployment in Tanium.

.DESCRIPTION
This endpoint starts an asynchronous Job to trigger a Package in Tanium which can manage Services.

.PARAMETER servername
Servername to grant access to. Validationpattern is '^[a-zA-Z0-9\-]{1,15}$'

.PARAMETER servicename
Name of the Service to manage. Validationpattern is '^[a-zA-Z0-9\-_. ]{1,50}$'

.PARAMETER desiredState
State which the Service should have. Possible values: 'Running' and 'Stopped'
#>
param(
    [Parameter(Mandatory = $true)]
    [string]
    $servername,

    [Parameter(Mandatory = $true)]
    [string]
    $servicename,

    [parameter(mandatory = $true)]
    [ValidateSet('Running', 'Stopped')]
    [string]
    $desiredState
)

Write-Debug -Message $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffK'))
Write-Debug -Message $($PSBoundParameters | Out-String)

$TokenValidationSucceded = $false
$InputValidationSucceded = $false
$ServerCIValidationSucceded = $false
$ContextValidationSucceded = $false
$StatusCode = 0
$ContextErrorCount = 0
$ErrorMessage = ''
$Body = @{}

$AccessParams = @{
    'Identity'     = $Identity;
    'Headers'      = $Headers;
    'AllowedUsers' = @(
        'service-account-api-os-windows',
        'service-account-api-sws-windows',
        'service-account-api-os-windows-pwshapi',
        'service-account-api-obm-sdms',
        'service-account-api-itsm-obm'
    )
    'APIMode'      = $SDMSAPIMode;
}
$AccessResult = Test-SDMSAPIAccess @AccessParams
$TokenValidationSucceded = $AccessResult.ValidationSucceded
$StatusCode = $AccessResult.StatusCode
$ErrorMessage = $AccessResult.ErrorMessage

if ($TokenValidationSucceded -eq $true) {
    $InputResult = Test-SDMSInputValidity -InputParameters $PSBoundParameters
    $InputValidationSucceded = $InputResult.ValidationSucceded
    $StatusCode = $InputResult.StatusCode
    $ErrorMessage = $InputResult.ErrorMessage
}

if ($InputValidationSucceded -eq $true) {
    $ServerCIParams = @{
        'Servername'               = $servername;
        'CIType'                   = 'nt';
        'SupportedLifecycleStates' = @('Build', 'Installed', 'In Use');
        'APIMode'                  = $SDMSAPIMode;
    }
    $ServerCIResult = Test-SDMSCIValidity @ServerCIParams
    $ServerCIValidationSucceded = $ServerCIResult.ValidationSucceded
    $StatusCode = $ServerCIResult.StatusCode
    $ErrorMessage = $ServerCIResult.ErrorMessage
}

if ($ServerCIValidationSucceded -eq $true) {
    if ($ContextErrorCount -eq 0) {
        $ContextValidationSucceded = $true
    } else {
        $ContextValidationSucceded = $false
        $StatusCode = 400
    }
}

if (
    $TokenValidationSucceded -eq $true -and
    $InputValidationSucceded -eq $true -and
    $ServerCIValidationSucceded -eq $true -and
    $ContextValidationSucceded -eq $true
) {
    try {
        $InvokeParams = @{
            'Script'           = 'Tanium\Set-ServiceStatus.ps1';
            'TargetClient'     = $servername;
            'PackageName'      = '[ASY-REPAIR] Service Management';
            'PackageParameter' = $servicename;
            'ParameterState'   = $desiredState;
            'Timeout'          = $timeout;
            'Integrated'       = $true;
        }
        $Result = Invoke-PSUScript @InvokeParams
        # The PSU cache is not persisent.
        # If the service or server is restarted, the cache is gone.
        # As a workaround we use the filesystem as a persistent cache.
        # Set-PSUCache -Key $SessionId -Value $Result.id
        New-Item -ItemType 'File' -Path $PersistentCache -Name $SessionId -Value $Result.id -Force -Confirm:$false | Out-Null
        $StatusCode = 201
    } catch {
        $StatusCode = 500
        $ErrorMessage = $_.Exception.Message
    }
}

if ($StatusCode -eq 201) {
    $Body['jobId'] = $SessionId
} else {
    $Body['httpStatus'] = $StatusCode
    $Body['errorMessage'] = $ErrorMessage
}
$Body = ConvertTo-Json -InputObject $Body -Compress -Depth 100
Write-Debug -Message $Body

$ContentType = 'application/json'
New-PSUApiResponse -StatusCode $StatusCode -Body $Body -ContentType $ContentType