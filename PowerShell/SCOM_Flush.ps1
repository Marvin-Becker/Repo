<#
.SYNOPSIS
This script restarts the WMI service and flushes the SCOM agent.
 
.DESCRIPTION
-
#>
 
<#
Author
Marvin Becker | NMD-I2.1 | Marvin.Becker@outlook.de
 
Date 14.11.2019
#>
 
 
# Variables
$scomService = Get-Service -Name HealthService
$wmiService = Get-Service -Name Winmgmt
[System.Collections.ArrayList]$ServicesToRestart = @()
 
function Custom-GetServiceDependencies ($ServiceInput) {
    Write-Host "Number of dependents: $($ServiceInput.DependentServices.Count)"
    If ($ServiceInput.DependentServices.Count -gt 0) {
        ForEach ($DepService in $ServiceInput.DependentServices) {
            Write-Host "Dependent of $($ServiceInput.Name): $($Service.Name)"
            If ($DepService.Status -eq "Running") {
                Write-Host "$($DepService.Name) is running."
                $CurrentService = Get-Service -Name $DepService.Name
                Custom-GetServiceDependencies $CurrentService
            } Else {
                Write-Host "$($DepService.Name) is stopped. No Need to stop or start or check dependencies."
            }
        }
    }
    if ($ServicesToRestart.Contains($ServiceInput.Name) -eq $false) {
        $ServicesToRestart.Add($ServiceInput.Name)
    }
}
 
# Restart WMI Service
# Getting dependencies for the WMI service
Custom-GetServiceDependencies -ServiceInput $wmiService
 
# Stop of dependent services
foreach ($ServiceToStop in $ServicesToRestart) {
    Write-Host "Stopping Service $ServiceToStop"
    Stop-Service $ServiceToStop -Verbose -Force
}
 
# Start of dependent services
$ServicesToRestart.Reverse()
foreach ($ServiceToStart in $ServicesToRestart) {
    Write-Host "Starting Service $ServiceToStart"
    Start-Service $ServiceToStart -Verbose
}
 
# SCOM Flush
if (Get-Service "HealthService") {
    Stop-Service $scomService.Name -Verbose
    Remove-Item -Path "C:\Program Files\Microsoft Monitoring Agent\Agent\Health Service State\*" -Recurse -Force
    Start-Service $scomService.Name -Verbose
    Write-Host "SCOM agent has been flushed." -ForegroundColor Green
} elseif (-not(Get-Service "HealthService")) {
    Write-Host "SCOM is not present on this server." -ForegroundColor Red
}
 
 
# Event log entries
$Source = "SCOM Flush"
$SourceExist = [System.Diagnostics.EventLog]::SourceExists($Source);
 
if (-not $SourceExist) {
    New-Eventlog -LogName Application -Source "SCOM Flush"
}
 
Write-EventLog -LogName Application -Source $Source -EventId 52001 -EntryType Information -Message "The SCOM agent has been flushed."