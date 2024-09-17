$json = Get-Content "C:\_Work\temp\DBMS\zero_byte.json" | ConvertFrom-Json 
$json | select Tenant, Environment, Machine, TimeStamp -ExpandProperty Data | Export-Excel 'C:\_Work\temp\DBMS\zero_byte.xlsx' -Show
