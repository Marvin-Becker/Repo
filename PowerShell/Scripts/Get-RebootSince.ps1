function Get-RebootSince() {
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "Format: MM.dd.yyyy")]
        [datetime]$Since
    )
    $Logs = Get-EventLog -LogName System -After $Since -Before (Get-Date) | Where-Object { $_.EventID -in (6005, 6006, 6008, 1074, 1076) } | Format-Table TimeGenerated, EventId, Message -AutoSize -Wrap
    Write-Output $Logs
}
Get-RebootSince -Since 
