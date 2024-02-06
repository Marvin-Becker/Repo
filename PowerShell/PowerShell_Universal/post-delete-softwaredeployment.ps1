<#
.SYNOPSIS
Trigger installation, removal or update of a software deployment in Tanium.

.DESCRIPTION
This endpoint starts an asynchronous Job to trigger a Package in Tanium. Only existing packages will run.

.PARAMETER servername
Servername to grant access to. Validationpattern is '^[a-zA-Z0-9\-]{1,15}$'

.PARAMETER softwarePackagename
Name of the Software-Package to trigger in Tanium. Validationpattern is '^[a-zA-Z0-9]{1,30}$'

.PARAMETER orderId
Order ID from the Order API. Validationpattern is '^ASYS-Order-[0-9]{7}$'
#>
param(
    [Parameter(Mandatory = $true)]
    [string]
    $servername,

    [parameter(Mandatory = $true)]
    [String]
    $softwarePackagename,

    [Parameter(Mandatory = $true)]
    [string]
    $orderId
)

Write-Debug -Message $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffK'))
Write-Debug -Message $($PSBoundParameters | Out-String)

$TokenValidationSucceded = $false
$InputValidationSucceded = $false
$OrderValidationSucceded = $false
$OrderNumberValidationSucceded = $false
$ServerCIValidationSucceded = $false
$ContextValidationSucceded = $false
$StatusCode = 0
$ContextErrorCount = 0
$ErrorMessage = ''
$Body = @{}

$AccessParams = @{
    'Identity'   = $Identity;
    'Headers'    = $Headers;
    'Servername' = $servername;
    'ScopeName'  = 'write';
    'RoleName'   = 'os-software-management_write';
    'APIMode'    = $SDMSAPIMode;
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
    $OrderResult = Test-SDMSOrderValidity -OrderID $orderId -APIMode $SDMSAPIMode
    $OrderValidationSucceded = $OrderResult.ValidationSucceded
    $StatusCode = $OrderResult.StatusCode
    $ErrorMessage = $OrderResult.ErrorMessage
}

if ($OrderValidationSucceded -eq $true) {
    $DebitorNumber = $OrderResult.ResponseContent._debitorNumber
    if ($InstallationOrderNumber) {
        $UseOrderNumber = $OrderResult.ResponseContent.installationOrderNumber
        $UseSubOrderNumber = $OrderResult.ResponseContent.installationSubOrderNumber
    } else {
        $UseOrderNumber = $OrderResult.ResponseContent.operationOrderNumber
        $UseSubOrderNumber = $OrderResult.ResponseContent.operationSubOrderNumber
    }
    $OrderNumberParams = @{
        'OrderNumber'    = $UseOrderNumber;
        'SubOrderNumber' = $UseSubOrderNumber;
        'DebitorNumber'  = $DebitorNumber;
        'APIMode'        = $SDMSAPIMode;
    }
    $OrderNumberResult = Test-SDMSOrderNumberValidity @OrderNumberParams
    $OrderNumberValidationSucceded = $OrderNumberResult.ValidationSucceded
    $StatusCode = $OrderNumberResult.StatusCode
    $ErrorMessage = $OrderNumberResult.ErrorMessage
}

if ($OrderNumberValidationSucceded -eq $true) {
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
    $PossiblePackages = @{
        'dotnet35' = '[ASY] .NET 3.5'
    }

    $PackageTimeout = @{
        'dotnet35' = 2100
    }

    if ($PossiblePackages.GetEnumerator().Name -contains $softwarePackagename) {
        $timeout = $PackageTimeout[$softwarePackagename]
        $softwarePackagename = $PossiblePackages[$softwarePackagename]
    } else {
        $PackageString = $PossiblePackages.GetEnumerator().Name -join ','
        $ErrorMessage = 'The argument ' + $softwarePackagename + ' does not match the following entries ' + $PackageString
        $StatusCode = 404
        $ContextErrorCount++
    }

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
    $OrderValidationSucceded -eq $true -and
    $OrderNumberValidationSucceded -eq $true -and
    $ServerCIValidationSucceded -eq $true -and
    $ContextValidationSucceded -eq $true
) {
    try {
        if ($Method -eq 'POST'){
            $Operation = 'install'
        } elseif ($Method -eq 'DELETE') {
            $Operation = 'remove'
        }

        $InvokeParams = @{
            'Script'              = 'Tanium\New-SingleDeployment.ps1'
            'TargetClient'        = $servername;
            'SoftwarePackagename' = $softwarePackagename;
            'Operation'           = $Operation;
            'Timeout'             = $timeout;
            'Integrated'          = $true;
        }
        $Result = Invoke-PSUScript @InvokeParams
        $RunID = $Result.RunId.Guid
        $StatusCode = 201
    } catch {
        $StatusCode = 500
        $ErrorMessage = $_.Exception.Message
    }
}

if ($StatusCode -eq 201) {
    $Body['jobId'] = $RunID
} else {
    $Body['httpStatus'] = $StatusCode
    $Body['errorMessage'] = $ErrorMessage
}
$Body = ConvertTo-Json -InputObject $Body -Compress -Depth 100
Write-Debug -Message $Body

$ContentType = 'application/json'
New-PSUApiResponse -StatusCode $StatusCode -Body $Body -ContentType $ContentType