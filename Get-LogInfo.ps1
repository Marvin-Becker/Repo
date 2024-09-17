try {
    $psqlCmd = Get-Command psql.exe -ErrorAction Stop
} catch {
    Throw $_.Exception.Message
}
$result = New-Object -TypeName "System.Collections.ArrayList"
$postgresPath = ($psqlCmd.Source) -replace ('\\bin\\.*') # "C:\Program Files\PostgreSQL\16" #\bin
$backupConf = Join-Path $postgresPath "Backup.conf"
if ( !(Test-Path $backupConf) ) {
    Throw "No Backup.conf found in '$postgresPath' ! Configure the Backup.conf at first!"
}
$backupRootPath = (Get-PropertyFileValue -Path $backupConf -Property "MEDAVIS_BACKUPROOT_PATH").Value
$logfile = Join-Path $BackupRootPath 'backup.log'

$content = Get-Content $logFile #| Where-Object { $_ -match $Cat }

$timeString = Get-Date -UFormat "%Y.%m.%d-%H:%M:%S"
$format = "yyyy.MM.dd-HH:mm:ss"
$time = [DateTime]::ParseExact($timeString, $format, $null)
$pattern = '\[(.*?)\]'
$regex = [regex]::new($pattern, 'IgnoreCase')
foreach ($line in $content) {
    if (($line -match 'ERROR|WARNING')) {
        $match = $regex.Match($line)
        $timestampString = $Match.Groups[1].Value
        $timestamp = [DateTime]::ParseExact($timestampString, $format, $null)
        if ( $timestamp -ge ($time.AddDays(-1)) ) {
            $result.Add($line) | Out-Null
        }
    }
}

$result