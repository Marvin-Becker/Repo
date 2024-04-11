Function Resolve-TTL {
    <#
    .SYNOPSIS
        Resolves TTL for a Serv in a domain. Default domain is set to server.server.de.
        If no Servername is given the Name of the local machine is assumed.

    .NOTES
        Name: Resolve-TTL
        Author: Marvin.Krischker@outlook.de
        Version: 1.0
        DateCreated: 2021-Nov-25


    .EXAMPLE
        Resolve-TTL -Computername "Servername"
        Resolve-TTL -Computername "Servername" -Domain server.server.de

    .LINK

    #>
        [CmdletBinding()]
        param(
            [Parameter(
                Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true,
                Position = 0
                )]
                [array]$computer = @($ENV:COMPUTERNAME),
            [Parameter(
                Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true,
                Position = 1
                )]
                [array]$domain = @("server.server.de")
        )
        BEGIN {
            $TTL = @()
        }
        PROCESS {
            foreach ($i in $computer){
                #if($PSBoundParameters.ContainsKey('domain')){
                    $fqdn = "$i.$domain"
                #}else{
                #    $fqdn = "$i"
                #}
                #Write-Host $fqdn
                $DNS = Resolve-DnsName $fqdn
                foreach ($j in $DNS){
                    $TTL = $j.TTL
                    $ts =  [timespan]::fromseconds($TTL)
                    $TTL_h = "{0:HH:mm:ss}" -f ([datetime]$ts.Ticks)
                    $TTL_Datetime = (Get-Date).AddSeconds($TTL)
                    $resolved = [PSCustomObject]@{
                        PSTypeName = 'TTL'
                        Name = $j.Name
                        Type = $j.Type
                        Section = $j.Section
                        IPAddress = $j.IPAddress
                        TTL = $j.TTL
                        TTL_h = $TTL_h
                        TTL_Datetime = $TTL_Datetime
                    }
                    [array]$result+=$resolved
                }
                Write-Verbose "TTL noch $TTL_h Stunden bis $TTL_Datetime"
            }
                return $result
        }
        END {}
    }
Resolve-TTL #-computer "" -Domain "server.server.de" -verbose | ft
