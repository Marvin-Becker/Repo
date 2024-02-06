
try{
Get-Content 'D:\1406\Neues Textdokument.tx' -ErrorAction Stop
}
catch{
$para=@{CheckFileExists = $true}
$dialog=[Microsoft.Win32.OpenFileDialog]$para
$datei=$dialog.ShowDialog()
$filename=($dialog.OpenFile()).Name
}




if ($filename -ne $null)
{
Notepad $filename
}
