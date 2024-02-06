$File = "C:\temp\Collections.csv"

### Members in Collection
$Collections = (Get-CMDeviceCollection | Where-Object { $_.Name -Like "EXCL_E*" }).Name
$Coll = [PSCustomObject]@{}

foreach ($Collection in $Collections) {
    $Members = (Get-CMCollectionMember -CollectionName $Collection).Name
    $Coll | Add-Member -type NoteProperty -Name $Collection -Value $Members
}

$Coll | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $File


### Collection and all Members once for CSV

$Collections = (Get-CMDeviceCollection | Where-Object { $_.Name -Like "EXCL*" }).Name

foreach ($Collection in $Collections) {
    $Members = (Get-CMCollectionMember -CollectionName $Collection).Name
    
    foreach ($Member in $Members) {
        Write-Output "$Collection;$Member" >> $File
    }
}


###
$JSON = Get-Content "C:\temp\Collections.json" | ConvertFrom-Json
$JSON = $JSON | Sort-Object Collections

$Object = @{}
$i = 0
[boolean]$NewCollection
$Object += @{$JSON.Collections[0] = $null }

foreach ($Collection in $JSON.Collections) {
    foreach ($Group in ($Object.GetEnumerator().Name)) {
        if ($Group -eq $Collection) {
            $Object[$Collection] += "," + $JSON.Member[$i]
            $NewCollection = $false
            break
        }
    } 
    if ($NewCollection) {
        $Object += @{$Collection = $JSON.Member[$i] }
    }  
    $i++
}

$Object
$Object.GetEnumerator() | Select-Object -Property Key, Value | Export-Csv -NoTypeInformation -Path c:\temp\Groups2.csv


###
$Collections = @("SCS-Weekly-FR-0100",
    "SCS-Weekly-FR-2000",
    "SCS-Weekly-FR-2200",
    "SCS-Weekly-MI-2300-RandomScan",
    "SCS-Weekly-MO-2300-RandomScan",
    "SCS-Weekly-SA-0001-RandomScan",
    "SCS-Weekly-SA-0100-CPULimit50",
    "SCS-Weekly-SA-0100-CPULimit80",
    "SCS-Weekly-SA-0101-RandomScan",
    "SCS-Weekly-SA-2200",
    "SCS-Weekly-SA-2300-RandomScan",
    "SCS-Weekly-SO-0300",
    "SCS-Weekly-SO-0300-CPULimit50",
    "SCS-Weekly-SO-0700-CPULimit50",
    "SCS-Weekly-SO-1200-RandomScan",
    "SCS-Weekly-SO-1900",
    "SCS-Weekly-SO-2300",
    "SCS-Weekly-TUE-1700",
    "SCS-Weekly-WED-1700",
    "SCS-Weekly-WED-1800")

$Object = @{}

foreach ($Collection in $Collections) {
    [string]$Members = (Get-CMCollectionMember -CollectionName $Collection).Name

    $Object += @{$Collection = $Members }
}

$Object.GetEnumerator() | Select-Object Name, Value | Export-Csv -NoTypeInformation -Delimiter ";" -Path c:\temp\Groups-SCS.csv