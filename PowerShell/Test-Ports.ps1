# SCRIPT:	PortTest.ps1
# CREATEDATE:	30.06.2016
# AUTHOR:	Carsten THies
# RACF:		THIE072
# E-MAIL:	Carsten.Thies@bertelsmann.de	
# PHONE:	+49 5241 80 42494
#
# Description:
#
# TCP Test for Windows or Active Directory Ruleset
# Changelog:		
# 
# Date:		Reason:					Name:
# -------------------------------------------------------------------------------------------
#30.12.2016 Add Timout Limit        THIE072



<#
.Synopsis
   Port-Test
.DESCRIPTION
   Testet eine TCP Verbindung
.Example
CheckTCPPorts -ZielIPListe 1.1.1.1 -PortListe 443
#>
function CheckTCPPorts
{

    param
    (
    [parameter(Mandatory=$true)]
    [String]$ZielIPListe,[String]$PortListe
    )

    foreach($IP in $ZielIPListe.Split(","))
    {
        foreach($Port in $PortListe.Split(","))
        {
            $TCPCon = New-Object Net.Sockets.TcpClient
            $ErrorActionPreference = 'SilentlyContinue'
           
            Write ""
            Write "Check Connection to $IP - $Port"
            $Connect = $TCPCon.BeginConnect($ip, $Port,$null,$null)
            
            $wait = $Connect.AsyncWaitHandle.WaitOne(5000,$false)


            if(-not $wait){
                Write ">> BLOCKED / NOT LISTEN"
                "$IP : Port $Port blocked/not listening."| Out-File -FilePath $AusgabePfad -Append

            }
            else{
                If($TCPCon.Connected){
                    Write ">> OPEN"
                    "$IP : Port $Port open" | Out-File -FilePath $AusgabePfad -Append
                    $TCPCon.EndConnect($connect) | out-Null 
                }else{
                    Write ">> BLOCKED / NOT LISTEN"
                    "$IP : Port $Port blocked/not listening."| Out-File -FilePath $AusgabePfad -Append
                }
            }

            $TCPCon.Dispose | Out-Null
            $TCPCon = $null | Out-Null
        }
    
    }

}



#########################################################
#### IP´s und Ports Festlegen der einzelnen Bereiche ####
#########################################################

$Datum = Get-Date -Format ("dd-MMM-yyyy")
$AusgabePfad = "C:\SZIR\BIN\PortTest_" + $Datum + ".txt"

If((Test-Path $AusgabePfad) -eq "True"){Remove-Item -Path $AusgabePfad}


$ArvatoDNSIPs = "145.228.121.70,145.228.121.80,145.228.185.40,145.228.185.60"
$ArvatoDNSPorts = "53"

$TivoliIPs = "145.228.111.183,145.228.111.20,145.228.111.241,145.228.111.49,145.228.111.50,145.228.183.12,145.228.183.6,145.228.183.85,145.228.39.95,145.228.78.57"
$TivoliPorts = "9494"

$TivoliManagementIPs  = "145.228.145.168,145.228.145.169"
$TivoliManagementPorts = "9494,9495,9496,8080,8443"

$KaroIPs = "10.13.68.16,10.13.68.17,145.228.183.127,145.228.39.158,145.228.39.221,145.228.39.24,84.17.191.21,84.17.191.44"
$KaroPorts = "80,443,7277,8080,8443"

$ProxyIPs = "145.228.181.7"
$ProxyPorts = "139,445,4480 "

$WinsIPs = "145.228.238.197,145.228.238.198,145.228.73.220"
$WinsPorts = "139"

$StreamworksIPs = "145.228.56.69,145.228.56.70,145.228.56.71,145.228.56.72" #old: "145.228.182.38,145.228.182.39"
$StreamworksPorts = "9600"


$SCCMIPs = "145.228.235.164"
$SCCMPorts = "80,443,445,8530,8531"


$DomainIPs
$DomainPorts = "53,88,135,389,445,464,636,3268,3269"
$Asysoffice = "10.13.68.18,10.13.68.19,10.13.68.27"
$Asysservice = "145.228.145.7,145.228.145.8"
$Bmedia = "145.228.73.20,145.228.181.45,145.228.158.54,145.228.237.69"


################################################
### Auswahl der zu prüfenden Freischaltungen ###
###############################################

cls

Write "###############################################"
Write "#         Windows Server Port Tester          #"
Write "#         V1.0 - 01.01.2017 - THIE072         #"
Write "###############################################"
Write ""
Write ""
Write "Welche Freischaltung soll geprüft werden?"
Write ""
Write "(1) Arvato DNS"
write "(2) Tivoli"
Write "(3) Tivoli Management"
Write "(4) Karo"
Write "(5) Proxy / DEZIRW07"
Write "(6) WINS"
Write "(7) Streamworks"
Write "(8) SCCM"
Write ""
Write "(A) AD Ports"
Write "(W) Windows Ruleset komplett"
Write ""

$Auswahl = Read-Host -Prompt "Bitte wählen"

#########################################################
### Aufruf der Windows Ruleset Parameter je nach Wahl ###
#########################################################

IF($Auswahl -eq "1" -or $Auswahl -eq "W")
    {
    Write ">>Check Arvato DNS - takes long time if ports are not open<<"
    "" | Out-File -FilePath $AusgabePfad -Append
    "Arvato DNS" | Out-File -FilePath $AusgabePfad -Append
    "" | Out-File -FilePath $AusgabePfad -Append

    CheckTCPPorts -ZielIPListe $ArvatoDNSIPs -PortListe $ArvatoDNSPorts
    }
if($Auswahl -eq "2" -or $Auswahl -eq "W")
    {
    Write ">>Check Tivoli - takes long time if ports are not open<<"
    "" | Out-File -FilePath $AusgabePfad -Append
    "Tivoli" | Out-File -FilePath $AusgabePfad -Append
    "" | Out-File -FilePath $AusgabePfad -Append
    CheckTCPPorts -ZielIPListe $TivoliIPs -PortListe $TivoliPorts
    }
if($Auswahl -eq "3" -or $Auswahl -eq "W")
    {
    Write ">>Check Tivoli Management Gateways - takes long time if ports are not open<<"
    "" | Out-File -FilePath $AusgabePfad -Append
    "Tivoli Management" | Out-File -FilePath $AusgabePfad -Append
    "" | Out-File -FilePath $AusgabePfad -Append
    CheckTCPPorts -ZielIPListe $TivoliManagementIPs -PortListe $TivoliManagementPorts
    }
if($Auswahl -eq "4" -or $Auswahl -eq "W")
    {
    Write ">>Check Karo - takes long time if ports are not open <<"
    "" | Out-File -FilePath $AusgabePfad -Append
    "Karo" | Out-File -FilePath $AusgabePfad -Append
    "" | Out-File -FilePath $AusgabePfad -Append
    CheckTCPPorts -ZielIPListe $KaroIPs  -PortListe $KaroPorts
    }
if($Auswahl -eq "5" -or $Auswahl -eq "W")
    {
    Write ">>Check Proxy / DEZIRW07 - takes long time if ports are not open<<"
    "" | Out-File -FilePath $AusgabePfad -Append
    "Softwaretankstelle / DEZIRW07" | Out-File -FilePath $AusgabePfad -Append
    "" | Out-File -FilePath $AusgabePfad -Append
    CheckTCPPorts -ZielIPListe $ProxyIPs -PortListe $ProxyPorts
    }
if($Auswahl -eq "6" -or $Auswahl -eq "W")
    {
    Write ">>Check WINS - takes long time if ports are not open<<"
    "" | Out-File -FilePath $AusgabePfad -Append
    "WINS" | Out-File -FilePath $AusgabePfad -Append
    "" | Out-File -FilePath $AusgabePfad -Append
    CheckTCPPorts -ZielIPListe $WinsIPs -PortListe $WinsPorts
    }
if($Auswahl -eq "7" -or $Auswahl -eq "W")
    {
    Write ">>Check Streamworks - takes long time if ports are not open<<"
    "" | Out-File -FilePath $AusgabePfad -Append
    "Streamworks" | Out-File -FilePath $AusgabePfad -Append
    "" | Out-File -FilePath $AusgabePfad -Append
    CheckTCPPorts -ZielIPListe $StreamworksIPs -PortListe $StreamworksPorts
    }
if($Auswahl -eq "8" -or $Auswahl -eq "W")
    {
    Write ">>Check SCCM - takes long time if ports are not open<<"
    "" | Out-File -FilePath $AusgabePfad -Append
    "SCCM" | Out-File -FilePath $AusgabePfad -Append
    "" | Out-File -FilePath $AusgabePfad -Append
    CheckTCPPorts -ZielIPListe $SCCMIPs -PortListe $SCCMPorts
    }



###################################################
### Auswahl der zu prüfenden AD Freischaltungen ###
###################################################

if($Auswahl -eq "A")
    {

    Write ""
    Write ""
    Write "Welche AD Controler sollen geprüft werden ? "
    Write ""
    Write "(1) Lokaler Primary / Secondary DNS"
    Write "(2) BMEDIA AD"
    Write "(3) Asysoffice AD"
    Write "(4) Asysservice AD"
    Write "(M) Manuell angeben"

    $AuswahlAD = Read-Host -Prompt "Bitte wählen"

####################################################
### Aufruf der AD Ruleset Parameter je nach Wahl ###
####################################################

### Auslesen der lokalen DNS Server - zwingend eine Karte mit *Dialog* im Namen ###

    $DialogKarte = Get-WmiObject Win32_NetworkAdapter | where {$_.NetConnectionID -like "*Dialog*"}
    $DNS = Get-WmiObject Win32_NetworkAdapterConfiguration | where {$_.InterfaceIndex -eq $DialogKarte.InterfaceIndex}

### Prüfung der Ports für lokale DNS / AD Server ###

    If($AuswahlAD -eq "1")
        {
        foreach($DomainIPs in $DNS.DNSServerSearchOrder)
            {
                Write ">>Check AD Connections - takes long time if ports are not open <<"
                "" | Out-File -FilePath $AusgabePfad -Append
                "Lokale DNS-Server / AD-Server" | Out-File -FilePath $AusgabePfad -Append
                "" | Out-File -FilePath $AusgabePfad -Append
                CheckTCPPorts -ZielIPListe $DomainIPs -PortListe $DomainPorts            
            }
            
        }

### Prüfung der Ports für Arvato Systems Domains ###    

    If($AuswahlAD -eq "2" -or $AuswahlAD -eq "3" -or $AuswahlAD -eq "4")
        {
             If($AuswahlAD -eq "2")
                {
                $DomainIPs = $Bmedia
                "BMEDIA AD-Server" | Out-File -FilePath $AusgabePfad -Append
                }
            If($AuswahlAD -eq "3")
                {
                $DomainIPs = $Asysoffice
                "Asysoffice AD-Server" | Out-File -FilePath $AusgabePfad -Append
                }
            If($AuswahlAD -eq "4")
                {
                $DomainIPs = $Asysservice
                "AsysofficeAD-Server" | Out-File -FilePath $AusgabePfad -Append
                }

            Write ">>Check AD Connections - takes long time if ports are not open <<"
            CheckTCPPorts -ZielIPListe $DomainIPs -PortListe $DomainPorts  



        }

### Prüfung der Ports für manuell eingegebene Domain IP´s ###

    If ($AuswahlAD -eq "M")
        {
            $Domain = $DNS.DNSDomain
            Write ""
            Write ""
            Write "Domain Contoller IP´s eingeben, ohne Leerzeichen und mit ',' getrennt:"
            $DomainIPs = Read-Host

            Write ">>Check AD Connections - takes long time if ports are not open <<"
            "" | Out-File -FilePath $AusgabePfad -Append
            "Domain Controller" | Out-File -FilePath $AusgabePfad -Append
            "" | Out-File -FilePath $AusgabePfad -Append
            CheckTCPPorts -ZielIPListe $DomainIPs -PortListe $DomainPorts

        }
     

    }

 start $AusgabePfad