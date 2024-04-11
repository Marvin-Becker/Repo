$EString = Read-Host "Enter Password" -AsSecureString
$BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($EString)
$DString=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$Encoded=[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($DString)) | out-file "C:\temp\EString.txt"
$password=[Text.Encoding]::Unicode.GetString([Convert]::FromBase64String((Get-Content "C:\temp\EString.txt")))

Net use X: \\gtlsccm2012\TempWriteInfo /user:gtlsccm2012\TempWriteInfo $password

### oder ###
$credential = Get-Credential
[String]$user = $credential.username
$credential.Password | ConvertFrom-SecureString | Set-Content "C:\temp\String.txt"
$password = Get-Content "C:\temp\String.txt" | ConvertTo-SecureString
#$credential = New-Object System.Management.Automation.PsCredential($username, $password)

Net use X: \\gtlsccm2012\TempWriteInfo /user:$user $password
