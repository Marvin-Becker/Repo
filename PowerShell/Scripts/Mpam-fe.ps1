$x64Path = "\\GTLSCCM2012\PCMS_Source\Microsoft\Endpoint Protection\EP-ClientInstall\PatternFilesUpdate\mpam-feX64.exe"
$x64url = "http://go.microsoft.com/fwlink/?LinkID=87341&amp;clcid=0x409" 
$webclient= new-object System.Net.WebClient
$webclient.DownloadFile( $x64url, $x64path ) 


### Mit Internetzugriff

$OSName = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption 
($OSName | Select-String -Pattern 'Windows' -Context 0) -match "[0-9]{4}"
$OSVersion = $Matches.Values

# Windows Server before 2016
if ($OSVersion -lt 2016) {
cmd /c "C:\Program Files\Microsoft Security Client\mpcmdrun -signatureupdate -mmpc"
}

# Windows Server 2016
if ($OSVersion -ge 2016) {
cmd /c "C:\Program Files\Windows Defender\mpcmdrun -signatureupdate -mmpc"
}


### von SCCM

net use M: "\\gtlsccm2012\PCMS_Source\Microsoft\Endpoint Protection\EP-ClientInstall\PatternFilesUpdate\" /user:gtlsccm2012\TempWriteInfo "09!e458v7nz03b9_4586z" #/user:XX\YY "Password"
robocopy "M:\mpam-feX64.exe" "C:\temp\mpam-feX64.exe" /R:1 /W:1
cmd /c "C:\temp\mpam-feX64.exe"
Start-Sleep -Seconds 20

# Check
$Result = @()
$AS = (Get-MpComputerStatus).AntispywareSignatureAge
$AV = (Get-MpComputerStatus).AntivirusSignatureAge
if ($AS -ge 7) {$Result += "- AntispywareSignatureAge is too old: $AS Days"} else {$Result += "- AntispywareSignatureAge is good: $AS Days"}
if ($AS -ge 7) {$Result += "- AntivirusSignatureAge is too old: $AV Days"} else {$Result += "- AntivirusSignatureAge is good: $AV Days"}
$Result