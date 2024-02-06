@echo off
sc config winmgmt start= disabled
net stop winmgmt /y
%systemdrive%
cd %windir%\system32\wbem
for /f %%s in ('dir /b *.dll') do regsvr32 /s %%s
wmiprvse /regserver
winmgmt /regserver
sc config winmgmt start= auto
net start winmgmt
for /f %%s in ('dir /s /b *.mof *.mfl') do mofcomp %%s


#Use this one with caution, as it resets the repository to the state it was in when Windows was installed. 
#This could break other parts of the system or applications.

#1. Disable and stop the WMI service.

     sc config winmgmt start= disabled

     net stop winmgmt

 
#2. Run the following commands.

     Winmgmt /salvagerepository %windir%\System32\wbem

     Winmgmt /resetrepository %windir%\System32\wbem


#3. Re-enable the WMI service and then reboot the server to see how it goes.

     sc config winmgmt start= auto


###If the problem remains, then try the following steps to rebuild the repository:

#1. Disable and stop the WMI service.

     sc config winmgmt start= disabled     #(note that there is a blank between '=' and 'disabled')

     net stop winmgmt


#2. Rename the repository folder (located at %windir%\System32\wbem\repository) to repository.old.


#3. Re-enable the WMI service.

     sc config winmgmt start= auto


#4. Reboot the server to see if the problem remains.