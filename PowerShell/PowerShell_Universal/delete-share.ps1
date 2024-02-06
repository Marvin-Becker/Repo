<#
.SYNOPSIS
Removing Share for SDMS API

.DESCRIPTION
This endpoint starts an asynchronous Job to remove a Share

.PARAMETER servername
Servername where the Share is hosted. Validationpattern is '^[a-zA-Z0-9\-]{1,15}$'

.Parameter driveletter
Assigned letter of the drive of the share. Possible values: Validationpattern is '^[e-yE-Y]{1}$'

.PARAMETER sharename
Name of Share. Possible values: Validationpattern is '^[a-zA-Z0-9\-_ ]{1,30}$'

.PARAMETER domain
Name of Domain. Possible values: Validationpattern is '^[a-zA-Z0-9\-]{1,30}$'

.PARAMETER deleteFolder
Wish to delete also the folder of the share. Possible values: 'true' or 'false'. Default is 'false'.

.PARAMETER orderId
Order ID from the Order API. Validationpattern is '^ASYS-Order-[0-9]{7}$'

.PARAMETER dryRun
Dry run to test workflow. Possible values: 'true' or 'false'. Default is 'true'.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]
    $servername,

    [Parameter(Mandatory = $true)]
    [string]
    $driveletter,

    [Parameter(Mandatory = $true)]
    [string]
    $sharename,

    [Parameter(Mandatory = $true)]
    [string]
    $domain,

    [Parameter(Mandatory = $true)]
    [boolean]
    $deleteFolder,

    [Parameter(Mandatory = $true)]
    [string]
    $orderId,

    [Parameter(Mandatory = $false)]
    [boolean]
    $dryRun = $true
)

Write-Debug -Message $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffK'))
Write-Debug -Message $($PSBoundParameters | Out-String)

$TokenValidationSucceded = $false
$InputValidationSucceded = $false
$OrderValidationSucceded = $false
$ServerCIValidationSucceded = $false
$StatusCode = 0
$ErrorMessage = ''
$Body = @{}

$AccessParams = @{
    'Identity'   = $Identity;
    'Headers'    = $Headers;
    'Servername' = $servername;
    'ScopeName'  = 'write';
    'RoleName'   = 'windows-filesystem-share_write';
    'APIMode'    = $SDMSAPIMode;
}
$AccessResult = Test-SDMSAPIAccess @AccessParams
$TokenValidationSucceded = $AccessResult.ValidationSucceded
$TokenUsername = $AccessResult.ResponseContent.preferred_username
$StatusCode = $AccessResult.StatusCode
$ErrorMessage = $AccessResult.ErrorMessage

if ($TokenValidationSucceded -eq $true) {
    $InputResult = Test-SDMSInputValidity -InputParameters $PSBoundParameters
    $InputValidationSucceded = $InputResult.ValidationSucceded
    $StatusCode = $InputResult.StatusCode
    $ErrorMessage = $InputResult.ErrorMessage
}

if ($InputValidationSucceded -eq $true) {
    $OrderResult = Test-SDMSOrderValidity -OrderID $orderId -APIMode $SDMSAPIMode
    $OrderValidationSucceded = $OrderResult.ValidationSucceded
    $StatusCode = $OrderResult.StatusCode
    $ErrorMessage = $OrderResult.ErrorMessage
}

if ($OrderValidationSucceded -eq $true) {
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

if (
    $TokenValidationSucceded -eq $true -and
    $InputValidationSucceded -eq $true -and
    $OrderValidationSucceded -eq $true -and
    $ServerCIValidationSucceded -eq $true
) {
    try {
        $InvokeParams = @{
            'Script'        = 'SDMS\Share\Remove-Share.ps1'
            'Servername'    = $servername;
            'Domain'        = $domain;
            'ShareDevice'   = $driveletter;
            'Sharename'     = $sharename;
            'DeleteFolder'  = $deleteFolder;
            'OrderID'       = $orderId;
            'SessionID'     = $SessionId;
            'TokenUsername' = $TokenUsername;
            'DryRun'        = $dryRun;
            'Integrated'    = $true;
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