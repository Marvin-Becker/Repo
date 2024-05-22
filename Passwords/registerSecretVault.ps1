Register-SecretVault -AllowClobber -Name 'RSServiceUser' -ModuleName 'SecretManagement.Keepass' -VaultParameters @{
    Path              = "C:\Keepass\RSServiceUser.kdbx"
    UseMasterPassword = $true
}
