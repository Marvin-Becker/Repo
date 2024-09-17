#ipmo octodeploy -Force
#ipmo Microsoft.PowerShell.SecretManagement -Force
#ipmo secretmanagement.keepass -Force

$environments = 'Test', 'Production' #'Development', 'QA', 
# Get all tenants that dont have a password for common variable "PostgreSQL Variables"
$alltenant = Get-Tenant | Where-Object Name -NotLike 'X*'
#$alltenant = Get-Tenant | Where-Object Name -Like 'XXDAA*'
$project = Get-Project 'ModernRIS'
#$t = Get-Tenant -Name 'XXDAA001'
#$environment = 'Development'#'QA'
foreach ($t in $alltenant) {
    $t.name
    foreach ($environment in $environments) {
        #Add-ProjectToTenant -Project $project -Tenant $t -Environment $environment
        #if (Get-ProjectTenantVariable -Project $project -Tenant $t -Environment $environment | Where-Object { $_.Name -eq "KeycloakAdminPassword" }) {
        #Write-Host "Tenant $($t.name) does not have a password in $environment, creating one"
        $password = New-Password -Length 20 -IncludeSpecialCharacters $false
        Set-ProjectTenantVariable -Project $project -Tenant $t -Environment $environment -Name "KeycloakDatabasePassword" -Value $password 
        Write-Host "Tenant $($t.name) password created and saved"
        Set-Secret -Name "$($t.name)-$($environment)" -Secret $password -Vault 'KeycloakDatabasePasswords'
        # } else {
        #     Write-Host "Tenant $($t.name) already has a password"
        # }
    }
}

#Test-SecretVault RSServiceUser