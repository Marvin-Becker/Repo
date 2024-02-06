:: ---------- Teil 1

for /f "tokens=9 delims= " %a IN ('echo list volume ^| diskpart ^| find "Boot"') do echo %a

DISKPART>List disk
:: As you can see, there are two local disks available in the system:
:: Disk 0 – a disk with GPT, Windows is installed on
:: Disk 1 – an empty unallocated disk

:: Clean the second disk again just in case and convert it into GPT:
Select disk 1
clean
Convert GPT

:: Display the list of partitions on the second disk:
List part
:: If there is at least one partition on the second Disk, delete it:
Sel part 1
Delete partition override

:: ---------- Teil 2
:: Display the list of partitions on first disk (disk 0)
Select disk 0
List part

:: Create the same partitions structure on Disk 1:
Select disk 1
Create partition primary size=450
format quick fs=ntfs label=”WinRE”
set id=”de94bba4-06d1-4d40-a16a-bfd50179d6ac”  > Gpttype für recovery partition
create partition efi size=99
create partition msr size=16
list part

:: Then convert both disks to dynamic:
Select disk 0
Convert dynamic
Select disk 1
Convert dynamic

:: Create a mirror for a system drive (drive letter C:).
:: Select a partition on Disk 0 and create a mirror for it on Disk 1:
Select volume c
Add disk=1
:: Open Disk Management and make sure that drive C: synchronization has been started (Resynching). 
:: Wait till it is over, it may take up to several hours depending on the size of the C: partition.


:: Assign the drive letter S: to the EFI partition on Disk 1 and format it in FAT32:
Select disk 1
Select part 2
assign letter=S
format fs=FAT32 quick

:: Then assign the letter P: to the EFI partition on Disk 0:
select disk 0
select partition 2
assign letter=P


