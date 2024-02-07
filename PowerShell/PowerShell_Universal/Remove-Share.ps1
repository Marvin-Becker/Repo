param (
    [Parameter(Mandatory = $true)]
    [string]
    $Servername,

    [Parameter(Mandatory = $true)]
    [string]
    $Domain,

    [Parameter(Mandatory = $true)]
    [string]
    $ShareDevice,

    [Parameter(Mandatory = $true)]
    [string]
    $Sharename,

    [Parameter(Mandatory = $true)]
    [boolean]
    $DeleteFolder,

    [Parameter(Mandatory = $false)]
    [string]
    $OrderID,

    [Parameter(Mandatory = $false)]
    [string]
    $SessionID,

    [Parameter(Mandatory = $false)]
    [string]
    $TokenUsername,

    [Parameter(Mandatory = $false)]
    [boolean]
    $DryRun = $true
)

$AvailableDomains = @{
    "AADDSRTLGROUP.COM"             = "AADDSRTLGROUP"
    "AD.LAMERS.AAM.LOCAL"           = "AD"
    "ADS.HETTICH.COM"               = "ADS"
    "ASYSAIRPLUS.DE"                = "APL"
    "PAYMENT.COM"                   = "PAYPMENT"
    "ARVSYS.LOC"                    = "ARVSYS"
    "ASYSDAAS.DE"                   = "ASYSDAAS"
    "ASYSEGK.DE"                    = "ASYSEGK"
    "ASYSOFFICE.DE"                 = "ASYSOFFICE"
    "ASYSSERVICE.DE"                = "ASYSSERVICE"
    "AXS.LOKAL"                     = "AXS"
    "BAGMAIL.NET"                   = "BAGMAIL"
    "BFSIS.NET"                     = "BFSIS"
    "BMEDIA.BAGINT.COM"             = "BMEDIA"
    "BMG.BAGINT.COM"                = "BMG"
    "CCMS4M.DE"                     = "CCMS4M"
    "DC01.EXPERT.APP.TELEFONICA.DE" = "DC01"
    "DE.ALFA.LOCAL"                 = "DE"
    "EXT.server-SERVICES.ORG "      = "DEASORG"
    "NAT.server-SERVICES.ORG "      = "DEASORG"
    "DKB-MANAGEMENT.LOC"            = "DKB"
    "DOMBD.ORG"                     = "DOMBD"
    "IPOSO.AD.DOM"                  = "DOMD20"
    "DOMHV.NET"                     = "DOMHV"
    "EMEA.DUERR.INT"                = "EMEA"
    "GT-DOM1.EU-GT.NET"             = "GT-DOM1"
    "AD.HANSA-FLEX.COM"             = "HANSA-FLEX"
    "HGROUP.INTRA"                  = "HGROUP"
    "server-INFOSCORE.NET"          = "IFS"
    "MAG.outlook.COM"               = "MAG"
    "CORP.MISUMI.EU"                = "MISUMIEU"
    "NLSMGMT.DE"                    = "NLSMGMT"
    "OGEDISP01.NET"                 = "OGEDISP01"
    "OTG.CORP.INT"                  = "OTG"
    "POSTADDRESS.GROUP"             = "PAG"
    "PHINEO.LOC"                    = "PHINEO"
    "RENK-AG.COM"                   = "RENKAG"
    "RENKNAVISION.LOC"              = "RENKNAVISION"
    "REYNHOLM-INDUSTRIES.TEST"      = "REYNHOLM"
    "SANICARE.LOCAL"                = "SANICARE"
    "SCHMI-RUD.DE"                  = "SCHMI-RUD"
    "ALFA.LOCAL"                    = "SEPNT1"
    "AD.SNLRD01.NL"                 = "SNLRD01"
    "STIEBEL-ELTRON.COM"            = "STE"
    "SWB-GRUPPE2.LOC"               = "SWB-GRUPPE2"
    "TNBW-A.NET"                    = "TNBW-A"
    "TNBW-P.NET"                    = "TNBW-P"
    "TRANSNETBW.DE"                 = "TRANSNETBW"
    "SYSTEMS-TRACKANDTRACE.DE"      = "TRT"
    "VRH.LOCAL"                     = "VRH"
    "ZEPPELIN-SHP.COM"              = "ZEPSHP"
}

$DomainName = $Domain.ToUpper()

if ( ($AvailableDomains.Values).foreach( { $_ -like "$DomainName" }) -ne $false ) {
    $Domain = $DomainName
} elseif ( ($AvailableDomains.Keys).foreach( { $_ -like "$DomainName" }) -ne $false ) {
    $Domain = $AvailableDomains["$DomainName"]
} else {
    throw 'Error: ' + $DomainName + ' not found in domain list.'
}

if ($OrderID -match '^ASYS-Order-[0-9]{7}$' -and $DryRun -eq $false) {
    if (!$SessionID) {
        throw 'Parameter sessionId is missing'
    }
    if (!$TokenUsername) {
        throw 'Parameter tokenUsername is missing'
    }

    $Description = 'Removal of ' + $Sharename + ' on ' + $Servername
    $OrderItemParams = @{
        'OrderID'            = $OrderID;
        'Description'        = $Description;
        'Servername'         = $Servername;
        'OrderItemMode'      = 'DELETE';
        'PSUJobID'           = $SessionID;
        'SDMSCallerUserName' = $TokenUsername;
        'APIMode'            = $SDMSAPIMode;
        'OrderItemDetails'   = @{
            'Sharename'   = $Sharename;
            'ShareDevice' = $ShareDevice;
            'Domain'      = $Domain
        };
    }
    $OrderItemResult = New-SDMSOrderItem @OrderItemParams
    $OrderItemID = (ConvertFrom-Json -InputObject $OrderItemResult)._id
}
try {
    $Params = @{
        'Servername'   = $Servername;
        'Sharename'    = $Sharename;
        'ShareDevice'  = $ShareDevice;
        'Domain'       = $Domain;
        'DeleteFolder' = $DeleteFolder;
        'DryRun'       = $DryRun;
        'APIMode'      = $SDMSAPIMode;
    }
    Remove-Share @Params | Out-Null
    $OrderItemStatus = 4
} catch {
    $ErrorMessage = $_
    $OrderItemStatus = 3
}

if ($OrderID -match '^ASYS-Order-[0-9]{7}$' -and $DryRun -eq $false) {
    $UpdateItemParams = @{
        'OrderID'         = $OrderID;
        'OrderItemID'     = $OrderItemID;
        'OrderItemStatus' = $OrderItemStatus;
        'APIMode'         = $SDMSAPIMode;
        'ErrorAction'     = 'Ignore'
    }
    Update-SDMSOrderItemStatus @UpdateItemParams | Out-Null
}

if ($ErrorMessage) {
    throw $ErrorMessage
}