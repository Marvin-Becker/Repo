<#
.SYNOPSIS
Trigger a new action deployment in Tanium.

.DESCRIPTION
This endpoint starts an asynchronous Job to trigger a Package in Tanium. Only existing packages will run.

.PARAMETER servername
Servername to grant access to. Validationpattern is '^[a-zA-Z0-9\-]{1,15}$'

.PARAMETER packagename
Packagename to trigger in Tanium. Validationpattern is '(\[ASY*[a-zA-Z0-9-_ ().]{1,20}\][a-zA-Z0-9-_ ().\[\]]{1,50})'

.PARAMETER dryRun
Dry run to test workflow
#>
param(
    [Parameter(Mandatory = $true)]
    [string]
    $servername,
    [parameter(Mandatory = $true)]
    [String]
    $packageName,
    [Parameter(Mandatory = $false)]
    [boolean]
    $dryRun = $true
)

$InputValidationSucceded = $false
$TokenValidationSucceded = $false
$SubprocessError = $false
$StatusCode = 0
$ErrorCount = 0
$ErrorMessage = ""
$Body = @{}

$sdmsUserToken = $Headers.'SDMS-USER-TOKEN'
if ($sdmsUserToken) {
    try {
        $TokenResult = (Test-SDMSKeycloakToken -AccessToken $sdmsUserToken -APIMode $SDMSAPIMode).content | ConvertFrom-Json
        $TokenUsername = $TokenResult.preferred_username
        $AccessParams = @{
            'Servername' = $servername;
            'Username'   = $TokenUsername;
            'ScopeName'  = 'write';
            'RoleName'   = 'os-access-management-v1_write';
            'APIMode'    = $SDMSAPIMode;
        }
        Test-ClientAccessViaServername @AccessParams | Out-Null
        $TokenValidationSucceded = $true
    } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        $StatusCode = $_.Exception.Response.StatusCode.Value__
        $Body = $_.ErrorDetails.Message
        $SubprocessError = $true
        $TokenValidationSucceded = $false
    } catch {
        $StatusCode = 500
        $ErrorMessage = $_.Exception.Message
        $TokenValidationSucceded = $false
    }
} elseif ($Identity -eq 'asysservice\sacsdms' -and !$sdmsUserToken) {
    $ErrorMessage = "SDMS-USER-TOKEN missing in header"
    $StatusCode = 401
    $TokenValidationSucceded = $false
} elseif ($Identity -ne 'asysservice\sacsdms') {
    $TokenValidationSucceded = $true
} else {
    $StatusCode = 500
    $ErrorMessage = 'Unexpected behaviour while verifying SDMS-USER-TOKEN'
    $TokenValidationSucceded = $false
}

if ($TokenValidationSucceded -eq $true) {

    $PossiblePackages = @(
        '[ASY-REPAIR] Heap Allocation'
    )

    if ($PossiblePackages -notcontains $packageName) {
        $PackageString = $PossiblePackages -join ','
        $ErrorMessage = "The argument '$($packageName)' does not match the following entries '$($PackageString)'"
        $ErrorCount++
    }

    $RegexServername = '^[a-zA-Z0-9\-]{1,15}$'
    if ($servername -notmatch $RegexServername) {
        $ErrorMessage = "The argument '$($servername)' does not match the pattern '$($RegexServername)'"
        $ErrorCount++
    }

    $RegexPackageName = '(\[ASY*[a-zA-Z0-9-_ ().]{1,20}\][a-zA-Z0-9-_ ().\[\]]{1,50})'
    if ($packageName -notmatch $RegexPackageName) {
        $ErrorMessage = "The argument '$($packageName)' does not match the pattern '$($RegexPackageName)'"
        $ErrorCount++
    }

    if ($ErrorCount -eq 0) {
        $InputValidationSucceded = $true
    } else {
        $InputValidationSucceded = $false
        $StatusCode = 400
    }
}

if (
    $TokenValidationSucceded -eq $true -and
    $InputValidationSucceded -eq $true
) {
    try {
        $InvokeParams = @{
            'Script'        = 'Tanium\New-ActionDeployment.ps1'
            'Servername'    = $servername;
            'PackageName'   = $packageName;
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
        $Body["jobId"] = $SessionId
    } catch {
        $StatusCode = 500
        $ErrorMessage = $_.Exception.Message
    }
}

if ($SubprocessError -eq $false) {
    if ($StatusCode -ne 201) {
        $Body["httpStatus"] = $StatusCode
        $Body["errorMessage"] = $ErrorMessage
    }
    $Body = ConvertTo-Json -InputObject $Body -Compress -Depth 100
}

$ContentType = 'application/json'
New-PSUApiResponse -StatusCode $StatusCode -Body $Body -ContentType $ContentType