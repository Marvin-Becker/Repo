$Processes = Get-Process | Sort-Object -Descending cpu | Select-Object CPU, ProcessName -First 10 | Where-Object { $_.CPU -ne $NULL }
$TotalCPU = Get-Process | Select-Object -expand CPU | Measure-Object -Sum | Select-Object -expand Sum
$UsedCPU = $NULL
ForEach ($Process in $Processes) {
    [int]$Perc = ($Process.CPU / $TotalCPU) * 100
    $UsedCPU = $UsedCPU + $Perc
    $Name = $Process.ProcessName
    Write-Output "$Name`: $Perc %"
}
Write-Output "Total used CPU: $UsedCPU %"


###########
Get-CimInstance Win32_Processor | Select-Object LoadPercentage

(Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum

Get-Counter -Counter '\Process(*)\% Processor Time' | Select-Object -ExpandProperty countersamples | Select-Object -Property instancename, cookedvalue | Sort-Object -Property cookedvalue -Descending | Select-Object -First 20 | ft InstanceName, @{L = 'CPU'; E = { ($_.Cookedvalue / 100).toString('P') } } -AutoSize

###########
$Procs = (Get-Counter -Counter "\Process(*)\% Processor Time").CounterSamples
$Procs | Where-Object CookedValue -GT "0" | Sort-Object -Property CookedValue -Descending | Format-Table -Property InstanceName, CookedValue -AutoSize


##### Prozess finden mit ProzessID
netstat -ano | findstr 8081
netstat -ano | findstr 8082
((netstat -anobv | Select-String -Pattern 'TCP(.*?)8081' -Context 1).Context.PostContext[1]) -replace '[ \[.exe\]]'
((netstat -anobv | Select-String -Pattern 'UDP(.*?)8082' -Context 1).Context.PostContext[1]) -replace '[ \[.exe\]]'
#$Process = (Get-Process | Where-Object { $_.Id -eq $ID }).ProcessName
$Process = (Get-Process -Id $ID).Name

# oder:
Get-NetTCPConnection -LocalPort 8081 | Select-Object -Property LocalAddress, LocalPort, RemoteAddress, RemotePort, State, @{'Name' = 'ProcessName'; 'Expression' = { (Get-Process -Id $_.OwningProcess).Name } } | ft
Get-NetUDPEndpoint -LocalPort 8082 | Select-Object -Property LocalAddress, LocalPort, RemoteAddress, RemotePort, State, @{'Name' = 'ProcessName'; 'Expression' = { (Get-Process -Id $_.OwningProcess).Name } } | ft

Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue | Where-Object OwningProcess -NE 0 | ForEach-Object { [string[]]$ProcessIDs8081 += $_.OwningProcess } 
if ($ProcessIDs8081) {
    $ProcessIDs8081 = $ProcessIDs8081 | Get-Unique
    foreach ($ID in $ProcessIDs8081) { [string[]]$ProcessProducts8081 += (Get-Process -Id $ID).Product }
    [string]$ProcessProducts8081 = $ProcessProducts8081 -join ','
    Write-Output "Port 8081 TCP is in use;$ProcessProducts8081;"
} else { Write-Output "No Process on Port 8081 TCP;No Software on Port 8081 TCP;" }
