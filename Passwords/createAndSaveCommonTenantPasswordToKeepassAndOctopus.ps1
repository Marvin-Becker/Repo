ipmo octodeploy -force
ipmo Microsoft.PowerShell.SecretManagement -Force
ipmo secretmanagement.keepass -Force

$environments = 'Development', 'QA', 'Test', 'Production'
# Get all tenants that dont have a password for common variable "PostgreSQL Variables"
$alltenant = Get-Tenant | Where-Object Name -NotLike 'XX*'

#$t = Get-Tenant -Name 'XXDAA001'
#$environment = 'QA'#'Development'
foreach ($t in $alltenant) {
    $t.name
    foreach ($environment in $environments) {
        if (Get-CommonTenantVariable -VariableSet 'PostgreSQL Variables' -Tenant $t | Where-Object { $_.Name -eq "PostgreSQL.SuperPassword[$environment]" -and $_.isdefaultValue -eq $true }) {
            Write-Host "Tenant $($t.name) does not have a password, creating one"
            $password = New-Password -Length 20 -IncludeSpecialCharacters $false
            Set-CommonTenantVariable -VariableSet 'PostgreSQL Variables' -Tenant $t -Name "PostgreSQL.SuperPassword[$environment]" -Value $password 
            Write-Host "Tenant $($t.name) password created and saved"
            Set-Secret -Name "$($t.name)-$environment" -Secret $password -Vault 'PostgresSuperPasswords'
        } else {
            Write-Host "Tenant $($t.name) already has a password"
        }
    }
}

Test-SecretVault PostgresSuperPasswords