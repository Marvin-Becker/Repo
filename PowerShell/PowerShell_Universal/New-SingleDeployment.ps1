param (
    [parameter(Mandatory = $true)]
    [String]
    $TargetClient,
    [parameter(Mandatory = $true)]
    [String]
    $SoftwarePackagename,
    [parameter(Mandatory = $true)]
    [Int]
    $Timeout,
    [parameter(Mandatory = $true, HelpMessage = 'install, update, remove or installOrUpdate')]
    [ValidateSet(
        'install',
        'update',
        'remove',
        'installOrUpdate'
    )]
    [String]
    $Operation = 'install'
)
New-SingleDeployment -TargetClient $TargetClient -SoftwarePackagename $SoftwarePackagename -Timeout $Timeout -Operation $Operation