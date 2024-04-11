function Check-Status() {
    [CmdletBinding()]
    [OutputType([String])]

    param(
        [string]$Path
    )

    $Minutes = 0
    do {
        $Status = Test-Path ($Path)
        Write-Output "Work in progress..."
        Start-Sleep -s 60
        $Minutes++
    }
    until (($Status -eq $False) -or ($Minutes -eq 60))
    if ($Minutes -eq 60) {
        Write-Output "Error: Something went wrong! It took already $Minutes Minutes and was aborted. Please check."
        Exit
    }
    Write-Output "Done! It took $Minutes Minutes."
}

$ENDP_AM = 'HKLM:\SOFTWARE\WOW6432Node\McAfee\Agent\Applications\ENDP_AM_1070'
$Rem_ENDP_AM = Get-ItemPropertyValue $ENDP_AM -name "Uninstall Command"
$Rem_ENDP_AM_Exe = $Rem_ENDP_AM.split('"')[1]
$Rem_ENDP_AM_Param = $Rem_ENDP_AM.split('"')[2]
& $Rem_ENDP_AM_Exe $Rem_ENDP_AM_Param
#"C:\Program Files\McAfee\Endpoint Security\Threat Prevention\RepairCache\SetupTP.exe" /x /removeespsynchronously /managed

Check-Status -Path $ENDP_AM

$ENDP_GS = 'HKLM:\SOFTWARE\WOW6432Node\Network Associates\ePolicy Orchestrator\Application Plugins\ENDP_GS_1070'
$Rem_ENDP_GS = Get-ItemPropertyValue $ENDP_GS -name "Uninstall Command"
$Rem_ENDP_GS_Exe = $Rem_ENDP_GS.split('"')[1]
$Rem_ENDP_GS_Param = $Rem_ENDP_GS.split('"')[2]
& $Rem_ENDP_GS_Exe $Rem_ENDP_GS_Param
#"C:\Program Files\McAfee\Endpoint Security\Endpoint Security Platform\RepairCache\SetupCC.exe" /x /managed

Check-Status -Path $ENDP_GS

$EpoAgent = 'HKLM:\SOFTWARE\WOW6432Node\Network Associates\ePolicy Orchestrator\Application Plugins\EPOAGENT3000'
$Rem_EpoAgent = Get-ItemPropertyValue $EpoAgent -name "Uninstall Command"
$Rem_EpoAgent_Exe = $Rem_EpoAgent.split('"')[1]
$Rem_EpoAgent_Param = $Rem_EpoAgent.split('"')[2]
& $Rem_EpoAgent_Exe $Rem_EpoAgent_Param
#"C:\Program Files\McAfee\Agent\x86\FrmInst.exe" /Remove=ALL /Silent

Check-Status -Path $EpoAgent
