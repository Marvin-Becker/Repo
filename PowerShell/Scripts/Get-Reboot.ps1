Get-EventLog -LogName System -After ([datetime]'06/13/2022 00:00:00') -Before (Get-Date) |Where-Object {$_.EventID -in (6005,6006,6008,1074,1076)} | ft TimeGenerated,EventId,Message -AutoSize –wrap

(Get-CimInstance -ClassName win32_operatingsystem).lastbootuptime