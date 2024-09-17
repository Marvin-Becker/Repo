# terminate running process
$processName = "chrome"
$processes = Get-Process -Name $processName -ErrorAction SilentlyContinue

if ($processes) {
    $processes | ForEach-Object { 
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction Stop
        } catch {
            $_.Exception.Message
        }
    }
    Write-Output "The $processName process has been terminated."
} else {
    Write-Output "No $processName process is currently running."
}