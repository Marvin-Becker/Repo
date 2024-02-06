<#
.SYNOPSIS
Open Shares Closure Script

.DESCRIPTION
This Script swaps out Everyone permissions in shares with Domain Users.
#>

<#
Author
Sebastian Moock | NMD-I2.1 | sebastian.moock@bertelsmann.de

Date
09.03.2021
#>


param (
	[parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
	[Alias("Name")]
	[string]$ComputerName
)


$adtools = Get-WindowsFeature -Name RSAT-AD-PowerShell
if (!($adtools.installed))
{
	Add-WindowsFeature RSAT-AD-PowerShell
}
Import-Module ActiveDirectory
Import-Module ServerManager

$Global:FinalResult = @()
$Global:MemberResult = @()

function Get-LocalGroups
{
	param (
		[parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("Name")]
		[string]$ComputerName
	)
	
	Get-WMIObject win32_group -filter "LocalAccount='True'" -computername $ComputerName | Select Name | Where-Object -FilterScript { $_.Name -eq "Administrators" -or $_.Name -eq "Remote Desktop Users" }
}


function Get-LocalGroupMembers
{
	param (
		[parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("Name")]
		[string]$ComputerName,
		[string]$GroupName
	)
	#Array Eigenschaften festlegen für die Variable $memberTable
	$GMemberProps = @{ Server = "$ComputerName"; LocalGroup = $GroupName; Name = ""; Type = ""; Domain = ""; ParentGroup = ""; Level = "0" }
	
	#Abfrage des Computernames, falls Ziel als IP angegeben wird.
	$hostname = (Get-WmiObject -ComputerName $ComputerName -Class Win32_ComputerSystem).Name
	#Abfrage der Gruppenmitglieder
	$wmi = Get-WmiObject -ComputerName $ComputerName -Query "SELECT * FROM Win32_GroupUser WHERE GroupComponent=`"Win32_Group.Domain='$Hostname',Name='$GroupName'`""
	
	if ($wmi -ne $null)
	{
		foreach ($value in $wmi)
		{
			#Array wird erstellt, worin die Daten abgelegt werden, damit diese an die beiden Globalen Arrays angehangen werden können.
			$MemberTable = New-Object psobject -Property $GMemberProps
			#Auslesen der Informationen aus der WMI Abfrage
			#Ergebniss kommt im Format Servername\User oder Domain\User
			$Data = $value.PartComponent -split "\,"
			$domain = ($data[0] -split "=")[1]
			$name = ($data[1] -split "=")[1]
			$MemberTable.name = $name.Replace("""", "")
			$MemberTable.Domain = $domain.Replace("""", "")
			$MemberTable.ParentGroup = $ComputerName.Replace("""", "")
			
			#Wenn die Domain dem Servernamen übereinstimmt handelt es sich um eine lokale Gruppe / User
			If (($domain.Replace("""", "")) -contains ($ComputerName.Replace("""", "")))
			{
				$MemberTable.Type = "local user or group"
			}
			else
			{
				#Prüfen ob User oder Gruppe
				$UName = $name.Replace("""", "")
				$UDom = $domain.Replace("""", "")
				$userobj = Get-ADUser -LDAPFilter "(SAMAccountName=$UName)" -Server $UDom
				
				If ($userobj -ne $null)
				{
					$MemberTable.Type = "domain user"
				}
				else
				{
					$MemberTable.Type = "domain group"
				}
				
				
			}
			
			#Ergebisse des Durchlaufs werden den globalen Array angehangen
			$Global:FinalResult += $MemberTable
			$Global:MemberResult += $MemberTable
		}
	}
}

function Get-MemberAndGroups
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[string]$Group,
		[String]$Domain,
		[String]$LocalGroup,
		[int]$Level
	)
	
	#Eigenschaften des Arrays für das Zwischenergebniss wird definiert.
	$GMemberProps = @{ Server = "$ComputerName"; LocalGroup = ""; Name = ""; Type = ""; Domain = ""; ParentGroup = ""; Level = "" }
	# Such nach Gruppenmitgliedern
	$members = Get-ADGroupMember -Identity $Group -Server $Domain -ErrorAction SilentlyContinue
	
	foreach ($member in $members)
	{
		
		# Wenn das Objekt eine Gruppe ist, werden die Informationen an das Array gehangen und
		# die Funktion ruft sich selbst mit der neuen Gruppe wieder auf.
		if ($member.objectClass -eq 'group')
		{
			
			If ($Domain -ne "BMEDIA")
			{
				## Umwandlung Distinuished Name in Domain FQDN
				$GroupDN = $member.distinguishedName
				$GroupDNArr = $GroupDN -Split (",DC=")
				$DomFQDNString = ""
				$ArrCount = 0
				
				Foreach ($value in $GroupDNArr)
				{
					If ($ArrCount -gt 0)
					{
						$DomFQDNString += $value + "."
					}
					$ArrCount++
				}
				$DomFQDN = $DomFQDNString.Substring(0, $DomFQDNString.Length - 1)
				
				#Daten werden in die Zwischentabell geschrieben
				$MemberTable = New-Object psobject -Property $GMemberProps
				$MemberTable.LocalGroup = $LocalGroup
				$MemberTable.Type = "domain group"
				$MemberTable.Domain = $DomFQDN
				$MemberTable.Name = $member.SamAccountName
				$MemberTable.ParentGroup = $Group
				$MemberTable.Level = $Level
				
				#Ergebnis wird an das globale Array gehangen
				$Global:FinalResult += $MemberTable
				
				Get-MemberAndGroups -Group $member.Name -Domain $DomFQDN -LocalGroup $LocalGroup -Level ($Level + 1)
			}
		}
		else
		{
			If ($Domain -ne "BMEDIA")
			{
				## Umwandlung Distinuished Name in Domain FQDN
				$GroupDN = $member.distinguishedName
				$GroupDNArr = $GroupDN -Split (",DC=")
				$DomFQDNString = ""
				$ArrCount = 0
				
				Foreach ($value in $GroupDNArr)
				{
					If ($ArrCount -gt 0)
					{
						$DomFQDNString += $value + "."
					}
					$ArrCount++
				}
				$DomFQDN = $DomFQDNString.Substring(0, $DomFQDNString.Length - 1)
				
				If ($Domain -ne "bmedia.bagint.com")
				{
					# Wenn es keine Gruppe ist, wird die User Info abgefragt.
					$MemberTable = New-Object psobject -Property $GMemberProps
					$MemberTable.LocalGroup = $LocalGroup
					$MemberTable.Type = "domain user"
					$MemberTable.Domain = $DomFQDN
					$MemberTable.Name = $member.SamAccountName
					$MemberTable.ParentGroup = $Group
					$MemberTable.Level = $Level
					
					#Ergebnis wird an das globale Array gehangen
					$Global:FinalResult += $MemberTable
				}
			}
		}
	}
}

If (!($ComputerName))
{
	#Write "Please insert Computername:"
	$ComputerName = $env:COMPUTERNAME
}

$LocalGroups = Get-LocalGroups -ComputerName $ComputerName

Foreach ($Group in $LocalGroups)
{
	Get-LocalGroupMembers -ComputerName $ComputerName -GroupName (($Group -split "=")[1]).Replace("}", "")
}

Foreach ($Member in $Global:MemberResult)
{
	If ($Member.Type -notlike "local*")
	{
		Get-MemberAndGroups -Group $member.Name -Domain $member.Domain -LocalGroup $Member.LocalGroup -Level ($Member.Level + 1)
	}
}


$CurrentDate = Get-Date -Format "yyyy-MM-dd"
$Outputfile = "C:\SZIR\$ComputerName" + "_user_report_" + "$CurrentDate.csv"

$Global:FinalResult | Export-Csv -Path $Outputfile -NoTypeInformation

<#
$scriptpath = Split-Path $MyInvocation.MyCommand.Path -Parent
$scriptname = Split-Path $MyInvocation.MyCommand.Path -Leaf
$modifieddate = (Get-Item $MyInvocation.MyCommand.Path).LastWriteTime.ToShortDateString() + " " + (Get-Item $MyInvocation.MyCommand.Path).LastWriteTime.ToShortTimeString()

Write "" | Out-File -FilePath $Outputfile -Encoding default -Append
Write "Path to script: $scriptpath" | Out-File -FilePath $Outputfile -Encoding default -Append
Write "Name of script: $scriptname" | Out-File -FilePath $Outputfile -Encoding default -Append
Write "Last modified: $modifieddate" | Out-File -FilePath $Outputfile -Encoding default -Append
#>