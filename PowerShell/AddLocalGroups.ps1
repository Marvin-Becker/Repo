$group = [ADSI]("WinNT://"+$env:COMPUTERNAME+"/administrators,group")
$group.add("WinNT://$env:USERDOMAIN/$groupNameAdminDL,group")
 
$group = [ADSI]("WinNT://"+$env:COMPUTERNAME+"/Remote Desktop Users,group")
$group.add("WinNT://$env:USERDOMAIN/$groupNameRDPDL,group")