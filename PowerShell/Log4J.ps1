$drives = GET-WMIOBJECT win32_logicaldisk

$Source = "asy_file"

$eventid = "815"

#$logfile2 = "c:\szir\asy_file2.txt"

$msg = @()

#$arrExtensions = "*.osiris","*.ozSjYiWh"
$arrExtensions = "log4j-core*"

# Define clear text string for username and password
[string]$userName = 'gtlsccm2012\TempWriteInfo'
[string]$userPassword = '09!e458v7nz03b9_4586z'

Net use X: \\gtlsccm2012\TempWriteInfo /user:gtlsccm2012\TempWriteInfo 09!e458v7nz03b9_4586z
$logfile = "X:\Log4J.log"



    foreach ($drive in $drives) {

        if ($drive.DriveType -eq 3) {

                $driveletter = $drive.DeviceID +"\"

                foreach($ext in $arrExtensions) {

                       $items = Get-ChildItem -recurse -force -filter $ext -erroraction silentlycontinue $driveletter | Select FullName #, CreationTime, LastWriteTime #| Format-Table -Wrap -AutoSize CreationTime, LastWriteTime, FullName
                       $items
                              if ($items -eq $null) {} else {
                                                        foreach($Pfad in $items)
                                                        {

                                                            $handle = C:\szir\bin\handle.exe ""$Pfad.FullName""

                                                            foreach ($line in $handle) {

                                                            if ($line -match '\S+\spid:') {
                                                                    $exe = $line
                                                              }
                                                              else { $exe = "No Filehandle" }

                                                                    }


                                                            #$items | out-file $logfile -Append
                                                            #$msg = $null
                                                            $msg = $env:COMPUTERNAME + ";" + $Pfad.FullName + ";" + $exe

                                                            $msg | out-file $logfile -Encoding utf8 -Append
                                                            #$msg | out-file $logfile2 -Encoding utf8 -Append

                                                        }
                                                    }
                                               }



                                    }

    }

     net use /del X:
