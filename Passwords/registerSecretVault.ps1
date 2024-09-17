Register-SecretVault -AllowClobber -Name 'KeycloakDatabasePasswords' -ModuleName 'SecretManagement.Keepass' -VaultParameters @{
    Path              = "C:\Keepass\KeycloakDatabasePasswords.kdbx"
    UseMasterPassword = $true
}
