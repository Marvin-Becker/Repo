function MigrateServer {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $ServerName,
        [parameter(Mandatory = $true)]
        [int32]
        $ReleaseVLANID,
        [parameter(Mandatory = $true)]
        [ipaddress]
        $ReleaseIP,
        [parameter(Mandatory = $true)]
        [int32]
        $ReferenceVLANID,
        [parameter(Mandatory = $true)]
        [ipaddress]
        $ReferenceIP,
        [parameter(Mandatory = $false)]
        [ValidatePattern('(?=^.{1,254}$)(^(?:(?!\d+\.|-)[a-zA-Z0-9_\-]{1,63}(?<!-)\.?)+(?:[a-zA-Z]{2,})\.?$)')]
        [string]
        $ZoneName = 'server.arvato-systems.de',
        [parameter(Mandatory = $true)]
        [ValidatePattern('(20[0-9]{9}WEB|SD[0-9]{8}|IM[0-9]{9}|C[0-9]{10}|OMM_.+|ASYS-Order-[0-9]{7}|TESTING|MIGRATION)')]
        [string]
        $OrderID,
        [parameter(Mandatory = $true)]
        [string]
        $Requestor
    )

    function Get-JobStatus {
        [CmdletBinding()]
        [OutputType([String])]
        param (
            [Parameter(Mandatory = $true)]
            [String]
            $JobID
        )

        do { 
            $Status = (Invoke-WebRequest -Uri "https://api.windows.arvato-systems.de/job/$JobID" -UseBasicParsing -UseDefaultCredentials -Method "GET" -Verbose).content
            sleep 5
        } until ( $Status.Contains("Completed") -OR $Status.Contains("Failed"))
        #$Status = '{ "jobOutput": {}, "jobError":"", "jobStatusName":"Failed", "jobStatus":3}'
        if ($Status.Contains("Completed")) { 
            Write-Output "Completed"
        } elseif ( $Status.Contains("Failed") ) {
            Write-Output $Status
        }
    }

    function New-WebRequest () {
        [CmdletBinding()]
        [OutputType([System.Object[]])]
        param (
            [Parameter(Mandatory = $true)]
            [string]
            $Repo,
            [Parameter(Mandatory = $true)]
            [string]
            $Method,
            [Parameter(Mandatory = $true)]
            [string]
            $Body
        )

        switch ($Repo) {
            'FNT' { $Path = 'fnt-net/v1/ipAddress' }
            'DNSforward' { $Path = 'dns/v1/forward' }
            'DNSreverse' { $Path = 'dns/v1/reverse' }
        }

        $Job = (Invoke-WebRequest -Uri "https://api.windows.arvato-systems.de/$Path" -UseBasicParsing -UseDefaultCredentials `
                -Method $Method -Body $Body -ContentType "application/json").content

        if ($Job) {
            $JobID = $Job.Replace("{`"jobId`":`"", "").Replace("`"}", "")
            Get-JobStatus -JobID $JobID
        }
    }

    # DELETE FNT
    New-WebRequest -Repo "FNT" -Method "DELETE" -Body '{ "ReleaseVLANID": $ReleaseVLANID, "ReleaseIP": $ReleaseIP, "Servername": $ServerName, "OrderID": $OrderID, "Requestor": $Requestor }' 
    
    # POST FNT
    New-WebRequest -Repo "FNT" -Method "POST" -Body '{ "ReferenceVLANID": $ReferenceVLANID, "ReferenceIP": $ReferenceIP, "Servername": $ServerName, "OrderID": $OrderID, "Requestor": $Requestor }'
    
    # DELETE Forward
    New-WebRequest -Repo "DNSforward" -Method "DELETE" -Body '{ "Servername": $ServerName, "ipaddress": $ReleaseIP }'
    
    # POST Forward
    New-WebRequest -Repo "DNSforward" -Method "POST" -Body '{ "Servername": $ServerName, "ipaddress": $IpAddressNew }'
    
    # DELETE Reverse
    New-WebRequest -Repo "DNSforward" -Method "DELETE" -Body '{ "Servername": $ServerName, "ipaddress": $ReleaseIP }'
    
    # POST Reverse
    New-WebRequest -Repo "DNSreverse" -Method "POST" -Body '{ "Servername": $ServerName, "ipaddress": $IpAddressNew }'
}