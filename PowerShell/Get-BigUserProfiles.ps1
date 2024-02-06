function Get-BigUserProfiles {
    $ErrorActionPreference = "SilentlyContinue"
 
    $UserFolders = Get-ChildItem -Path "C:\Users" -Force -Directory
 
    ForEach ( $Folder in $UserFolders ) {
 
        [UInt64]$FolderSize = ( Get-ChildItem -Path $Folder.FullName -Force -Recurse | Measure-Object -Property "Length" -Sum).Sum
     
        [PSCustomObject]@{
            FolderName = $Folder.BaseName
            FolderPath = $Folder.FullName
            Size       = $FolderSize
        }
    }
}
 
Get-BigUserProfiles | Sort-Object -Property Size