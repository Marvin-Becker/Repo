function Set-UserProfilePath{
    <#
          .SYNOPSIS
          Changes User Profile Path for all existing and new Users from one Drive to another. Ex. C:\Users to E:\Users
          Copies all existing Profiles.
          .DESCRIPTION
          Changes User Profile Path for all existing and new Users from one Drive to another.
          Copies all existing Profiles. Except majestics and User running the Script. (Because of open file restrictions)
          Creates Backup of Registry Path before editing. (in C:\SZIR\BIN\)
          Changes the entries under ProfileList for ProfilesDirectory, Default, Public and all Users in the List. Skips majestics and User running the Script. (Because we didn't copy their folders)
          .EXAMPLE
          Set-UserProfilePath -OldDrive C: -NewDrive E:
          Set-UserProfilePath -OldDrive C: -NewDrive E: -Incident IM123456789
          .LINK
          -
    #>
    Param(
         
        [ArgumentCompleter({"C:"})]
        [Parameter(Mandatory="TRUE",HelpMessage='Enter Origin Drive ex. C:')]
        [ValidatePattern('^([A-Z]\:)')]
        [string]$OldDrive = 'C:',
        [ArgumentCompleter({"E:"})]
        [ValidatePattern('^([A-Z]\:)')]
        [Parameter(Mandatory="TRUE",HelpMessage='Enter New Drive ex. E:')]
        [string]$NewDrive = 'E:',
        [string]$Incident
        )
    #Backup Reg Keys
    $strExportRegKey = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $strExportPath = "C:\SZIR\BIN"
    if (-not (Test-Path -Path $strExportPath)){
        $strExportPath = $env:Temp
    }
    if($Incident){
        $strExportFileName = $Incident + "_$(get-date -f yyyyMMddhhmmss).reg"
    }
    else{
        $strExportFileName = "Backup_$(get-date -f yyyyMMddhhmmss).reg"
    }
    $strExport = $strExportPath + "\" + $strExportFileName
    reg export $strExportRegKey $strExport /y
 
    #Set Default Path and Path for User Default and Public
    $ProfilesDirectory = $NewDrive + '\Users'
    $Default = $NewDrive + '\Users\Default'
    $Public = $NewDrive + '\Users\Public'
    set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' -Name ProfilesDirectory -Value $ProfilesDirectory
    set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' -Name Default -Value $Default
    set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' -Name Public -Value $Public
    
    #Copy existing profiles exclude current user due to open files
    $strCurrentUserPath = $env:USERPROFILE
    $strMajesticsPath = "C:\Users\Administrator"
    robocopy C:\Users $ProfilesDirectory /e /copyall /xj /sl /log:robocopy.log /R:3 /W:3 /tee /ZB /XD $strCurrentUserPath $strMajesticsPath
 
    #Change Path Value for existing Profiles in Registry
    $Profiles = (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' | where-object { ($_.PSChildName.Length -gt 8) -and ($_.PSChildName -notlike "*.DEFAULT")})
    $strCurrentUserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $strSIDMajestics = (New-Object System.Security.Principal.NTAccount('majestics')).Translate([System.Security.Principal.SecurityIdentifier]).Value
    foreach ($i in $Profiles){
        #Skip for current user and majestics
        if (($i.PSChildName -eq $strCurrentUserSID) -or ($i.PSChildName -eq $strSIDMajestics))
        {Continue}
         
        $profilePath = $i | Get-ItemPropertyValue -Name ProfileImagePath
        $profilePathNew = $profilePath.Replace($OldDrive,$NewDrive)
        #Write-Host "Alt:" $profilePath "Neu:" $profilePathNew
        $i | Set-ItemProperty -Name ProfileImagePath -Value $profilePathNew
    }
}
Set-UserProfilePath -OldDrive C: -NewDrive E: -Incident IM