$services = 'HL7', 'Mail', 'Report-Index', 'DocConverter'

# Stop dependend services
foreach ( $service in $services ) {
    try {
        $srv = $null
        $srv = Get-Service -DisplayName "medavis*$service*"
        if ($srv) {
            Stop-Service $srv -Verbose
            # wait for service process to stop. Sometimes the service is stopped but the process is still running for a couple of seconds
            While (-not $srv.processID -eq 0 -and (Get-Process -Id $srv.processID -ErrorAction SilentlyContinue)) {
                Write-Host "Waiting for service '$($srv.Name)' to stop" -ForegroundColor 'yellow'
                Start-Sleep 1
            }
        }
    } catch {
        Write-Host "Could not stop service $service"
    }
}
