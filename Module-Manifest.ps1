$manifest = @{
    Path              = 'C:\_Work\customermailing-module\CustomerMailing.psd1'
    RootModule        = 'CustomerMailing.psm1'
    ModuleVersion     = '1.0.0' 
    GUID              = '3f8b5078-4a3d-4b57-b5a5-42e0f6e8f05d'
    Author            = 'Marvin Becker'
    CompanyName       = 'medavis GmbH'
    Copyright         = '(c) 2024. All rights reserved.'
    Description       = 'Module for customer mailing functions'
    FunctionsToExport = @(
        'ConvertTo-HtmlUmlaut',
        'Set-DefaultParams',
        'Get-RecipientExcel',
        'Get-RecipientOcto',
        'Get-Translation',
        'Invoke-CustomerMail',
        'Send-InfoMail',
        'Send-MailMessage',
        'Send-UpdateMail',
        'Write-InfoEmail',
        'Write-UpdateEmail'
    )
}

New-ModuleManifest -Path $manifest.Path -ModuleToProcess $manifest