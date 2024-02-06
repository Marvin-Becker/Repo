set DT=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%

robocopy "\\Server\share_von" "\\Server\share_zu" /E /R:1 /W:1 /MIR /COPYALL /MT:16 /SECFIX /ZB /XJ /DCOPY:T /XD "$RECYCLE.BIN" "System Volume Information" /XF "thumbs.db" /LOG:"C:\Logfiles\robocopy_%DT%.log"
