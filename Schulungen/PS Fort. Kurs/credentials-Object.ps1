# Nicht nachmachen  ... ;-)


$Cred = New-Object System.Management.Automation.PSCredential $Username, $SecureString


$Cred = New-Object System.Management.Automation.PSCredential "Domain\Administrator", (ConvertTo-SecureString -AsPlainText "Passw0rd" -Force)