#ipmo octodeploy -Force
#ipmo Microsoft.PowerShell.SecretManagement -Force
#ipmo secretmanagement.keepass -Force

$environments = 'Development', 'QA', 'Test', 'Production'
# Get all tenants that dont have a password for common variable "PostgreSQL Variables"
$alltenant = Get-Tenant | Where-Object Name -NotLike 'X*'
$project = 'Install RS'
#$t = Get-Tenant -Name 'XXDAA001'
#$environment = 'Development'#'QA'
foreach ($t in $alltenant) {
    $t.name
    foreach ($environment in $environments) {
        if ( Get-ProjectTenantVariable -Project $project -Tenant $t -Environment $environment -ErrorAction SilentlyContinue ) {
            if (Get-ProjectTenantVariable -Project $project -Tenant $t -Environment $environment | Where-Object { $_.Name -eq "rsServiceUserPassword" -and $_.isdefaultValue -eq $true }) {
                Write-Host "Tenant $($t.name) does not have a password in $environment, creating one"
                $password = New-Password -Length 20 -IncludeSpecialCharacters $false
                Set-ProjectTenantVariable -Project $project -Tenant $t -Environment $environment -Name "rsServiceUserPassword" -Value $password 
                Write-Host "Tenant $($t.name) password created and saved"
                Set-Secret -Name "$($t.name)-$($environment)" -Secret $password -Vault 'RSServiceUser'
            } else {
                Write-Host "Tenant $($t.name) already has a password"
            }
        } else {
            Write-Host "Tenant $($t.name) not connected in $environment"
        }
    }
}

#Test-SecretVault RSServiceUser