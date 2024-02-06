$registryPathSCEP = "HKLM:\SOFTWARE\Policies\Microsoft\Microsoft Antimalware\MpEngine"
$registryPathDefender = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine"

$Name = "MpEnableTest"
[string]$value = "40603"

IF((Test-Path $registryPathSCEP)) {
    # System Center Endpoint Protection found
    $returnValue = Get-ItemPropertyValue -Path $registryPathSCEP -Name $Name
    return "SCEP Set to: $returnValue"
} ELSEIF ((Test-Path $registryPathDefender)) {
    # Defender found
    $returnValue = Get-ItemPropertyValue -Path $registryPathDefender -Name $Name
    return "Defender Set to: $returnValue"
}
else {
    # Nothing found
    return "No Key found"
} 


### Remove

$registryPathSCEP = "HKLM:\SOFTWARE\Policies\Microsoft\Microsoft Antimalware\MpEngine"
$registryPathDefender = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine"

$Name = "MpEnableTest"
[string]$value = "40603"

IF((Test-Path $registryPathSCEP)) {
    # System Center Endpoint Protection found
    Remove-ItemProperty -Path $registryPathSCEP -Name $name -Force | Out-Null
    $returnValue = Get-ItemPropertyValue -Path $registryPathSCEP -Name $Name
    return "SCEP Set to: $returnValue"
} ELSEIF ((Test-Path $registryPathDefender)) {
    # Defender found
    Remove-ItemProperty -Path $registryPathDefender -Name $name -Force | Out-Null
    $returnValue = Get-ItemPropertyValue -Path $registryPathDefender -Name $Name
    return "Defender Set to: $returnValue"
}
else {
    # Nothing found
    return "No Key found"
} 
