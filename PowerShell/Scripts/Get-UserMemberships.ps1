$ADModule = (Get-WindowsFeature -Name RSAT-AD-PowerShell).installed
if (-not($ADModule.installed)) {
    Add-WindowsFeature RSAT-AD-PowerShell
}
Import-Module ActiveDirectory

function Get-UserMembership() {
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "AD-Accountname")]
        [string[]]$Users,
        [Parameter(Mandatory = $False, HelpMessage = "Domain where the user is")]
        [string]$Domain
    )

    BEGIN {
        $Result = @()

        if ($PSBoundParameters.ContainsKey('Domain')) {
            [String]$DC = (Get-ADDomainController -DomainName $Domain -Discover -NextClosestSite).Hostname
        }
    }

    PROCESS {
        foreach ($User in $Users) {
            if ($DC) {
                $ADuser = Get-ADUser -Server $DC -Identity $User
                $token = (Get-ADUser -Server $DC -Identity $ADuser -Properties tokengroups).tokengroups
            } else {
                $ADuser = Get-ADUser -Identity $User
                $token = (Get-ADUser -Identity $ADuser -Properties tokengroups).tokengroups
            }
            $Result += "$User is member of:"
            ForEach ($group in $token) {
                $groupname = $group.Translate([System.Security.Principal.NTAccount])
                $Result += $groupname.value
            }
        }
    }

    END {
        Return $Result
    }
}
Get-UserMembership -Users "" -Domain swb-gruppe.local