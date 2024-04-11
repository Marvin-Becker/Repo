Function Get-LastLoginInfo {
    #requires -RunAsAdministrator
    <#
    .Synopsis
        This will get a Information on the last users who logged into a machine.
        More info can be found: https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/basic-audit-logon-events

    .NOTES
        Name: Get-LastLoginInfo
        Author: Marvin.Becker@outlook.de
        Version: 1.1
        DateCreated: 2020-Nov-27
        DateUpdated: 2022-Sep-23

    .EXAMPLE
        Get-LastLoginInfo -ComputerName Server01, Server02, PC03 -SamAccountName username
        Get-LastLoginInfo -ComputerName Server01, Server02, PC03 -SamAccountName username -DaysFromToday 30

    .LINK
        https://thesysadminchannel.com/get-computer-last-login-information-using-powershell -
    #>

    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [Parameter(
            Position = 1,
            Mandatory = $false,
            ParameterSetName = "Include"
        )]
        [string]$SamAccountName,
        [Parameter(
            Position = 1,
            Mandatory = $false,
            ParameterSetName = "Exclude"
        )]
        [string]$ExcludeSamAccountName,
        [Parameter(
            Mandatory = $false
        )]
        [ValidateSet(3, 5, 7, 10, 21, 24, 25, 39, 40)]
        [int[]]$LogonType = @(3, 5, 7, 10, 21, 24, 25, 39, 40),
        [Parameter(
            Mandatory = $false
        )]
        [int]$DaysFromToday = 3,
        [Parameter(
            Mandatory = $false
        )]
        [int]$MaxEvents = 1024,
        [System.Management.Automation.PSCredential]
        $Credential,
        [Parameter(
            Mandatory = $false
        )]
        [datetime]$Date
    )

    BEGIN {
        if ($PSBoundParameters.ContainsKey('DaysFromToday')) {
            $StartDate = (Get-Date).AddDays(-$DaysFromToday)
            $EndDate = (Get-Date)
        } elseif ($PSBoundParameters.ContainsKey('Date')) {
            [datetime]$StartDate = $Date
            [datetime]$EndDate = $StartDate.AddDays(-1)
        }
    }

    PROCESS {
        foreach ($Computer in $ComputerName) {
            try {
                $Computer = $Computer.ToUpper()
                $Time = "{0:F0}" -f (New-TimeSpan -Start $StartDate -End $EndDate | Select-Object -ExpandProperty TotalMilliseconds) -as [int64]

                if ($PSBoundParameters.ContainsKey("SamAccountName")) {
                    $EventData = "
                        *[EventData[
                                Data[@Name='TargetUserName'] != 'SYSTEM' and
                                Data[@Name='TargetUserName'] != '$($Computer)$' and
                                Data[@Name='TargetUserName'] = '$($SamAccountName)'
                            ]
                        ]
                    "
                }

                if ($PSBoundParameters.ContainsKey("ExcludeSamAccountName")) {
                    $EventData = "
                        *[EventData[
                                Data[@Name='TargetUserName'] != 'SYSTEM' and
                                Data[@Name='TargetUserName'] != '$($Computer)$' and
                                Data[@Name='TargetUserName'] != '$($ExcludeSamAccountName)'
                            ]
                        ]
                    "
                }

                if ((-not $PSBoundParameters.ContainsKey("SamAccountName")) -and (-not $PSBoundParameters.ContainsKey("ExcludeSamAccountName"))) {
                    $EventData = "
                        *[EventData[
                                Data[@Name='TargetUserName'] != 'SYSTEM' and
                                Data[@Name='TargetUserName'] != '$($Computer)$'
                            ]
                        ]
                    "
                }

                $Filter = @"
                    <QueryList>
                        <Query Id="0" Path="Security">
                            <Select Path="Security">
                                *[System[(EventID=4624 or EventID=4625 or EventID=4778 or EventID=4779) and TimeCreated[timediff(@SystemTime)`
                                 &lt;= $($Time)]]] and $EventData
                            </Select>
                        </Query>
                    </QueryList>
"@ #Cannot be indented. Search "here-string indentation" for explanation.
                $FilterLocalSessionManager = @"
                    <QueryList>
                        <Query Id="0" Path="Microsoft-Windows-TerminalServices-LocalSessionManager/Operational">
                            <Select Path="Microsoft-Windows-TerminalServices-LocalSessionManager/Operational">
                                *[System[(EventID=21 or EventID=24 or EventID=25 or EventID=39 or EventID=40) and TimeCreated[timediff(@SystemTime)`
                                 &lt;= $($Time)]]]
                            </Select>
                        </Query>
                    </QueryList>
"@ #Cannot be indented. Search "here-string indentation" for explanation.

                if ($PSBoundParameters.ContainsKey("Credential")) {
                    $EventLogList = Get-WinEvent -ComputerName $Computer -FilterXml $Filter -Credential $Credential -ErrorAction Stop
                    $EventLogList2 += Get-WinEvent -ComputerName $Computer -FilterXml $FilterLocalSessionManager -Credential $Credential -EA Stop
                } else {
                    $EventLogList = Get-WinEvent -ComputerName $Computer -FilterXml $Filter -ErrorAction Stop
                    $EventLogList2 = Get-WinEvent -ComputerName $Computer -FilterXml $FilterLocalSessionManager -ErrorAction Stop
                }

                $Output = foreach ($Log in $EventLogList) {
                    #Removing seconds and milliseconds from timestamp as this is allow duplicate entries to be displayed
                    $TimeStamp = $Log.timeCReated
                    $TimeStamp = $TimeStamp#.ToString("dd.MM.yyyy HH:mm:ss")

                    switch ($Log.Properties[8].Value) {
                        2 { $LoginType = '2  - Interactive (local logon)'; break }
                        3 {
                            $LoginType = '3  - Network (connection to shared folder)'
                            $UserName = $Log.Properties[5].Value; break 
                        }
                        4 { $LoginType = '4  - Batch'; break }
                        5 { $LoginType = '5  - Service'; break }
                        7 { $LoginType = '7  - Unlock (after screensaver)'; break }
                        8 { $LoginType = '8  - NetworkCleartext'; break }
                        9 { $LoginType = '9  - NewCredentials (local impersonation process under existing connection)'; break }
                        10 { $LoginType = '10 - RDP'; break }
                        11 { $LoginType = '11 - CachedInteractive'; break }
                        default { $LoginType = "LogType Not Recognised: $($_.LogonType)"; break }
                    }

                    if (($Log.Properties[8].Value -in ($LogonType)) -or $Log.ID -in (4778, 4779)) {
                        [PSCustomObject]@{
                            ComputerName = $Computer
                            TimeStamp    = $TimeStamp
                            UserName     = $UserName
                            LoginType    = $LoginType
                            EventID      = $Log.ID
                            SessionID    = ''
                        }
                    }
                }
                $Output += foreach ($Log2 in $EventLogList2) {
                    $TimeStamp = $Log2.timeCReated
                    $TimeStamp = $TimeStamp#.ToString("dd.MM.yyyy HH:mm:ss")
                    try {
                        $UserName = ($Log2.Properties[0].Value.toLower()).split('\')[1]
                        $SessionID = $Log2.Properties[1].Value
                    } catch {
                        $UserName = ''
                        $SessionID = $Log2.Properties[0].Value
                    }
                    switch ($Log2.ID) {
                        21 { $LoginType = '21 - Shell start notification received'; break }
                        24 { $LoginType = '24 - Session has been disconnected'; break }
                        25 { $LoginType = '25 - Session reconnection succeeded'; break }
                        39 {
                            $Reason = $Log2.Properties[1].Value
                            $LoginType = '39 - Session ' + $SessionID + ' has been disconnected by session ' + $Reason
                            break
                        }
                        40 {
                            $Reason = $Log2.Properties[1].Value
                            $LoginType = '40 -Session ' + $SessionID + ' has been disconnected, reason code ' + $Reason
                            break
                        }
                    }

                    if ((($PSBoundParameters.ContainsKey("SamAccountName") -and ($SamAccountName -eq $UserName) -and ($Log2.ID -in ($LogonType)))`
                                -or (-not $PSBoundParameters.ContainsKey("SamAccountName"))) -and ($Log2.ID -in ($LogonType))) {
                        [PSCustomObject]@{
                            ComputerName = $Computer
                            TimeStamp    = $TimeStamp
                            UserName     = $UserName
                            LoginType    = $LoginType
                            EventID      = $Log2.ID
                            SessionID    = $SessionID
                        }
                    }
                }

                #Because of duplicate items, we'll append another select object to grab only unique objects
                $Output = $Output | Select-Object ComputerName, TimeStamp, UserName, SessionID, LoginType, EventID | Select-Object -First $MaxEvents
                $Output = $Output | Sort-Object TimeStamp -Descending
            } catch {
                Write-Error $_.Exception.Message
            }
        }
    }

    END {
        return $Output
    }
}