function Set-NtauthsvcToSvc(){
    param(
    [parameter(Mandatory = $True)][String]$SVC
    )

$sdshow = (sc.exe sdshow $SVC)[1]
Write-Host "Current Config:" -ForegroundColor Yellow
$sdshow
if(-not ($sdshow.Contains("(A;;CCLCSWLOCRRC;;;SU)"))){
    $sdshow += "(A;;CCLCSWLOCRRC;;;SU)"
    sc.exe sdset $SVC $sdshow
    Write-Host "String set" -ForegroundColor Green
    $sdshow
} else {Write-Host "String already there" -ForegroundColor Yellow}
}
Set-NtauthsvcToSvc -SVC mslldp
