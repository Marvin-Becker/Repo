### Direkt nach KB suchen
Set-ExecutionPolicy Bypass

$KB = "KB5014702"

$Update = Get-HotFix | Where-Object HotFixID -eq $KB

if ($Update) {
    $HotFixID = $Update.HotFixId
    $InstalledOn = $Update.InstalledOn
    Write-Output "Update $HotFixID installed on $InstalledOn"
} else {
    Write-Output "Update $KB missing, trying to install..."
    Copy-Item "\\tsclient\Z\Install\PSWindowsUpdate" -Destination "%WINDIR%\System32\WindowsPowerShell\v1.0\Modules" -Force -Recurse
    Import-Module PSWindowsUpdate
    Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d
    if ((Get-WUInstall –MicrosoftUpdate -ListOnly).KB -contains $KB) {
        Write-Output "$KB available, trying to install it..."
        Hide-WUUpdate –KBArticleID $KB –MicrosoftUpdate –HideStatus:$false –Confirm:$false
    } else { Write-output "$KB not avaiable" }
}

### ausstehende KBs anzeigen lassen und dann entscheiden 
Set-ExecutionPolicy Bypass
Copy-Item "\\tsclient\Z\Install\PSWindowsUpdate" -Destination "%WINDIR%\System32\WindowsPowerShell\v1.0\Modules" -Force -Recurse
Import-Module PSWindowsUpdate
Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d
Get-WUInstall –MicrosoftUpdate -ListOnly | Out-GridView
$KB = Read-Host -Prompt "Enter the KB you want to install (e.g. KB1234567)"
if ($KB) {
    Hide-WUUpdate –KBArticleID $KB –MicrosoftUpdate –HideStatus:$false –Confirm:$false
}