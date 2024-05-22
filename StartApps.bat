@echo off
rem start "" "C:\Program Files (x86)\Sophos\Connect\GUI\scgui.exe"
start "" "C:\Program Files\KeePass Password Safe 2\KeePass.exe"
start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
start "" "C:\Program Files (x86)\Microsoft Office\root\Office16\OUTLOOK.EXE"
rem start "" "C:\Program Files\Microsoft Office\root\Office16\ONENOTE.EXE"
rem start "" "C:\Program Files\Notepad++\notepad++.exe"
start "" "shell:appsfolder\Microsoft.Office.OneNote_8wekyb3d8bbwe!Microsoft.OneNoteim"
rem start "" "C:\Users\marvin.becker\AppData\Local\Programs\Microsoft VS Code\Code.exe"
start "" "code"
start "%windir%\System32\mmc.exe" "%windir%\System32\virtmgmt.msc"
rem start "" "C:\Ditto\DittoPortable.exe"
rem start "%systemroot%\system32\mstsc.exe" "C:\Users\marvin.becker\AppData\Roaming\Microsoft\Workspaces\{57ED7E48-7C4C-4B31-8FEB-C1F6B518561C}\Resource\CAS genesisWorld (Work Resources).rdp"
timeout /t 10 rem /nobreak
Exit