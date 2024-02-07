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
        [int32]
        $TimeToLive = 86400,
        [parameter(Mandatory = $false)]
        [ValidatePattern('(?=^.{1,254}$)(^(?:(?!\d+\.|-)[a-zA-Z0-9_\-]{1,63}(?<!-)\.?)+(?:[a-zA-Z]{2,})\.?$)')]
        [string]
        $ZoneName = 'server.server.de',
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
            $Status = (Invoke-WebRequest -Uri "https://api.windows.server.de/job/$JobID" -UseBasicParsing -UseDefaultCredentials -Method "GET").content
        } until ( $Status.Contains("Completed") -OR $Status.Contains("Failed"))
        #$Status = '{ "jobOutput": {}, "jobError":"", "jobStatusName":"Failed", "jobStatus":3}'
        if ( $Status.Contains("Failed") ) {
            Write-Output $Status
            Exit
        } else { Write-Output "Completed" }
    }

    # POST FNT
    $Content = (Invoke-WebRequest -Uri 'https://api.windows.server.de/fnt-net/v1/ipAddress' -UseBasicParsing -UseDefaultCredentials `
            -Method "POST" -Body '{ "ReferenceVLANID": $ReferenceVLANID, "ReferenceIP": $ReferenceIP, "Servername": $ServerName, "OrderID": $OrderID, "Requestor": $Requestor }' -ContentType "application/json").content
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    Get-JobStatus -JobID $JobID
    
    # DELETE FNT
    $Content = (Invoke-WebRequest -Uri 'https://api.windows.server.de/fnt-net/v1/ipAddress' -UseBasicParsing -UseDefaultCredentials `
            -Method "DELETE" -Body '{ "ReleaseVLANID": $ReleaseVLANID, "ReleaseIP": $ReleaseIP, "Servername": $ServerName, "OrderID": $OrderID, "Requestor": $Requestor }' -ContentType "application/json").content
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    Get-JobStatus -JobID $JobID

    # POST Forward
    $Content = (Invoke-WebRequest -Uri 'https://api.windows.server.de/dns/v1/forward' -UseBasicParsing -UseDefaultCredentials `
            -Method "POST" -Body '{ "Servername": $ServerName, "ipaddress": $IpAddressNew }' -ContentType "application/json").content
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    Get-JobStatus -JobID $JobID

    # DELETE Forward
    $Content = (Invoke-WebRequest -Uri 'https://api.windows.server.de/dns/v1/forward' -UseBasicParsing -UseDefaultCredentials `
            -Method "DELETE" -Body '{ "Servername": $ServerName, "ipaddress": $ReleaseIP }' -ContentType "application/json").content
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    Get-JobStatus -JobID $JobID

    # POST Reverse
    $Content = (Invoke-WebRequest -Uri 'https://api.windows.server.de/dns/v1/reverse' -UseBasicParsing -UseDefaultCredentials `
            -Method "POST" -Body '{ "Servername": $ServerName, "ipaddress": $IpAddressNew }' -ContentType "application/json").content
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    Get-JobStatus -JobID $JobID

    # DELETE Reverse
    $Content = (Invoke-WebRequest -Uri 'https://api.windows.server.de/dns/v1/reverse' -UseBasicParsing -UseDefaultCredentials `
            -Method "DELETE" -Body '{ "Servername": $ServerName, "ipaddress": $ReleaseIP }' -ContentType "application/json").content
    $JobID = $Content.Replace("{`"jobId`":`"", "").Replace("`"}", "")
    Get-JobStatus -JobID $JobID
}