################ Notes ##################

##### Test-Server ####
VMware Test
VLAN_2489
ISO einbinden über \\gtlnmiwvm1827\install$
UEFI-Server: Test-marvin
10.6.255.10
10.6.255.1
BIOS-Server: marvin-Test
10.6.255.12
10.6.255.1

VCD:
marvintest01
10.161.207.136
MqeyWPmL_RlU4A*i2T9EasJ%

Blade im Testcenter:
gtasswnq01733-t
172.28.89.30
172.28.89.1
255.255.255.128

<#
$copybmgr = @()
$copybmgr += "for /f `"tokens=7 delims=. `" %a IN ('bcdedit /copy {bootmgr} /d `"Windows Boot Manager Cloned`"') do echo %a"
$bootmgr = $copybmgr | cmd
$bootmgr -match '{.*}'
#>

function Test-Regex {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]$Pattern,
        [parameter(Mandatory = $true)][String]$String
    )

    $FullPattern = "(?smi)$Pattern"
    $Regex = New-Object regex($FullPattern)
    $Result = $Regex.Matches($String)
    if ($Result.Count -eq 0) {
        return $false
    } else {
        return $true
    }
}



#Diskpart aufrufen mit Powershell in einem Array:
$diskpart = @()
$diskpart += "SELECT DISK $systemdisk_nr"
$diskpart += "detail disk"
$diskpart += "exit"
#Ausgabe
$result = $diskpart | diskpart


# Always finds "Volume #" so we start at -1
$PartCount = -1
for ($line = 0; $line -lt $result.Count; $line++) {
    if ($result[$line] -like "*Volume*") {
        $PartCount++
    }
}

# Display the list of partitions on first disk (disk 0)
Get-Disk | select *



<#
#jede partition auslesen (GPTType,Size) und dementsprechend neu anlegen > Get-Partition | select *
$systemparts = Get-Partition -DiskNumber $systemdisk_nr
foreach ($i in $systemparts){
	#neue Parts anlegen
	#Gpttype für verschiedene Partitionen
	#Testausgabe: Write-Host $i.xx
	New-Partition -DiskNumber $mirrordisk_nr -gpttype $i.gpttype -driveletter $i.driveletter -size $i.size
}
#>


#format mirrordisk
Get-Partition -DiskNumber $mirrordisk_nr -PartitionNumber 1 | Format-Volume -FileSystem NTFS
