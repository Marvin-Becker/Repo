### Find files with Name
$Path = ''
$Item = ''
[string[]]$Findings = (Get-ChildItem -Path $Path -Recurse | Where-Object { ($_.Name -like $Item) }).Fullname
$Findings

Remove-Item $Findings[0] -Recurse -Force -Verbose -ErrorAction SilentlyContinue

### Find modified Files
$Path = ''
[string[]]$Findings = (Get-ChildItem -Path $Path -Recurse | Where-Object { ($_.LastWriteTime.Date -gt (Get-Date).addDays(-1) -and -not $_.PSIsContainer ) }).Fullname

foreach ($Finding in $Findings) {
    Remove-Item $Finding -Recurse -Force -Verbose -ErrorAction SilentlyContinue
}


[string[]]$Findings = (Get-ChildItem -Path $Path -Recurse | Sort-Object -Property LastAccessTime | Where-Object { $_.lastwritetime -gt (Get-Date).addDays(-30) -and -not $_.PSIsContainer }).FullName


### Find big folders
$Path = 'C:'
[string[]]$Findings = (Get-ChildItem -Path $Path )
$Arraylist = New-Object -TypeName "System.Collections.ArrayList"
foreach ($f in $Findings) {
    $Items = (Get-ChildItem -Recurse “$Path\$f” -ErrorAction SilentlyContinue | Measure-Object -Property length -Sum -ErrorAction SilentlyContinue)
    $Size = "$Path`\$f`: " + “{0:N2}” -f ($Items.sum / 1GB) + ” GB”
    $Arraylist.Add($Size)
}
$Arraylist

###
$Path = "C:"
[string[]]$Findings = (Get-ChildItem -Path $Path )
#$Arraylist = New-Object -TypeName "System.Collections.ArrayList"
foreach ($f in $Findings) {
    Get-ChildItem -Recurse “$Path\$f” -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue `
    | Format-Table @{Label = "Path"; Expression = { "$Path" } }, @{n = "Size(GB)"; e = { [math]::Round((($_.Sum) / 1GB), 2) } }
}

### 
$Path = 'C:\Install'
[string[]]$Findings = (Get-ChildItem -Path $Path)
$Hash = [ordered]@{}
foreach ($f in $Findings) {
    $Items = (Get-ChildItem -Recurse “$Path\$f” -ErrorAction SilentlyContinue | Measure-Object -Property length -Sum -ErrorAction SilentlyContinue)
    $Size = “{0:N2}” -f ($Items.sum / 1MB) + ” MB”
    $Hash.Add("$Path`\$f", $Size)
}
$Hash
$Hash.GetEnumerator() | Sort-Object Values
$Hash = $NULL

(Get-ChildItem "C:\Install" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property length -Sum -ErrorAction SilentlyContinue)