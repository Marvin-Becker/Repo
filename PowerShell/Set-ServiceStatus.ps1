<#
.SYNOPSIS
    This Script will set the given service to the desired state.
.NOTES
    Name: Set-ServiceStatus
    Author: Marvin Becker | KRIS085 | NMD-FS4.1 | Marvin.Becker@bertelsmann.de
    Date Created: 01.06.2023
    Last Update: 16.06.2023
.EXAMPLE
    Set-ServiceStatus -ServiceName Spooler -DesiredState Stopped
#>
param(
    [parameter(mandatory = $true)]
    [string]$ServiceName,
    [parameter(mandatory = $true)]
    [ValidateSet('Running', 'Stopped')]
    [string]$DesiredState
)

[string]$Info = ''
$RC = 0
[string]$ErrorMessage = ''
$Result = @()

try {
    $Service = Get-Service -ErrorAction Stop | Where-Object { $_.Name -like "*$ServiceName*" }
} catch {
    $RC = 1
    throw 'There is no service like ' + $ServiceName + '.'
}

$Status = $Service.Status
$Info += $($Service.DisplayName) + ' is in status: ' + $Status + '. '

if ( $DesiredState -eq 'Running') {
    switch ($Status) {
        'Stopping' {
            try {
                $Info += ' Need to stop the process of ' + $($Service.DisplayName) + ' before it can be started.'
                $ServiceLabel = $Service.Name
                $ProcessId = Get-CimInstance -ClassName Win32_Service -Filter "Name LIKE `"$ServiceLabel`"" `
                    -ErrorVariable $ProcessError -ErrorAction Stop | Select-Object -ExpandProperty ProcessId
                $Info += ' Trying to kill the process... '
                Stop-Process -Id $ProcessId -Verbose -Force -ErrorVariable $StopProcessError -ErrorAction Stop
            } catch {
                $RC = 1
                if ( $ProcessError ) {
                    $ErrorMessage += ' Could not find any running process for service ' + $($Service.DisplayName) + ' to stop. '
                } elseif ( $StopProcessError ) {
                    $ErrorMessage += ' Could not stop process for service ' + $($Service.DisplayName) + '. '
                }
            }
            try {
                Start-Service $Service.Name -Verbose -ErrorAction Stop
                $Info += ' Started ' + $($Service.DisplayName) + '.'
            } catch [Microsoft.PowerShell.Commands.StartServiceCommand], [Microsoft.PowerShell.Commands.SetServiceCommand] {
                $RC = 1
                $ErrorMessage += $($Service.DisplayName) + ' could not be started. '
            }
        }

        'Stopped' {
            $Info += ' Trying to start the service... '
            try {
                Start-Service $Service.Name -Verbose -ErrorAction Stop
                $Info += ' Started ' + $($Service.DisplayName) + '. '
            } catch {
                $RC = 1
                $ErrorMessage += $($Service.DisplayName) + ' could not be started. '
            }
        }

        'Running' {
            $Info += ' Trying to restart the service... '
            try {
                Restart-Service $Service.Name -Verbose -Force -ErrorAction Stop
                $Info += ' Restarted ' + $($Service.DisplayName) + '.'
            } catch {
                $RC = 1
                $ErrorMessage += $($Service.DisplayName) + ' could not be restarted. '
            }
        }
    }
} elseif ( $DesiredState -eq 'Stopped') {
    switch ($Status) {
        'Stopping' {
            $ServiceLabel = $Service.Name
            $ProcessId = Get-CimInstance -ClassName Win32_Service -Filter "Name LIKE `"$ServiceLabel`"" `
                -ErrorVariable $ProcessError -ErrorAction Stop | Select-Object -ExpandProperty ProcessId
            $Info += ' Trying to kill the process... '
            try {
                Stop-Process -Id $ProcessId -Verbose -Force -ErrorVariable $StopProcessError -ErrorAction Stop
                $Info += ' Stopped ' + $($Service.DisplayName) + '. '
            } catch [Microsoft.PowerShell.Commands.StartServiceCommand], [Microsoft.PowerShell.Commands.SetServiceCommand] {
                $RC = 1
                if ( $ProcessError ) {
                    $ErrorMessage += ' Could not find any running process for service ' + $($Service.DisplayName) + ' to stop. '
                } elseif ( $StopProcessError ) {
                    $ErrorMessage += ' Could not stop process for service ' + $($Service.DisplayName) + '. '
                }
            }
        }

        'Stopped' {
            $Info += $($Service.DisplayName) + ' is already stopped. '
        }

        'Running' {
            $Info += ' Trying to stop the Service... '
            try {
                Stop-Service -Name $Service.Name -Verbose -Force -ErrorAction Stop
                $Info += ' Stopped ' + $($Service.DisplayName) + '. '
            } catch [Microsoft.PowerShell.Commands.StartServiceCommand], [Microsoft.PowerShell.Commands.SetServiceCommand] {
                $RC = 1
                $ErrorMessage += $($Service.DisplayName) + ' could not be stopped. '
            }
        }
    }
}


if ( $RC -eq 0 ) {
    $ServiceNew = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$ServiceName*" }
    $StatusNew = $ServiceNew.Status
    if ($StatusNew -eq $DesiredState) {
        $Info += ' Desired State ' + $DesiredState + ' of Service ' + $($ServiceNew.DisplayName) + ' confirmed.'
    } else {
        $Info += ' Cannot confirm desired State ' + $DesiredState + ' of Service ' + $($ServiceNew.DisplayName) + '.'
    }
}

$Result = [PSCustomObject]@{
    'Info'         = $Info
    'Returncode'   = $RC
    'Errormessage' = $ErrorMessage
}
return $Result

