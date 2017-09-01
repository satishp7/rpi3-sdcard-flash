# rpi3-sdcard-flash
SD card flash script for rpi3 android build - works for linux enviornment<br />

Flash script to prepare sd card for android images<br />
    
script usage is to format and copy android build images for raspberry pi 3
android<br />
    
usage:<br />
./mkmmc.sh -d <sd card device>  -and <android source dir>  -kernel <kernel dir>

<br />
e.g.
sudo ./mkmmc.sh -d /dev/mmcblk0 -and ~/projects/raspb/ -kernel ~/projects/raspb/kernel/rpi/

<br />
if out directory is on other location then add parameter: -out <out dir path>

<br />
Sample output:<br />
raspb_flash$ sudo ./mkmmc.sh -d /dev/mmcblk0 -and ~/projects/raspb/ -kernel ~/projects/raspb/kernel/rpi/

<br />
Boot dir:<home dir for user>/projects/raspb//device/brcm/rpi3/boot<br />
Android out:<home dir for user>/projects/raspb//out/target/product/rpi3<br />
<br />
  -- DEVICE mmcblk0 --<br />
mmcblk0 manfid: 0x00009c<br />
mmcblk0 name  : USD00<br />
mmcblk0 size  : 15103 MB<br />

[Unmounting all existing partitions on the device ]<br />
  unmounting mmcblk0p1 (/dev/mmcblk0p1 on /media/boot type vfat)<br />
  unmounting mmcblk0p2 (/dev/mmcblk0p2 on /media/system type ext4)<br />
  unmounting mmcblk0p3 (/dev/mmcblk0p3 on /media/cache type ext4)<br />
  unmounting mmcblk0p4 (/dev/mmcblk0p4 on /media/userdata type ext4)<br />

All data on /dev/mmcblk0 now will be destroyed! Continue? [y/n]<br />
y<br />
[Partitioning /dev/mmcblk0...]<br />
DISK SIZE - 15836643328 bytes<br />
CYLINDERS - 1925<br />
[Partprobe /dev/mmcblk0...]<br />
[Making filesystems...]<br />
[Formating boot...]<br />
[Formating system...]<br />
[Formating cache...]<br />
[Formating userdata...]<br />
[Copying files...]<br />
[Copying boot...]<br />
[Copying system...]<br />
[Done]<br />
raspb_flash$<br /> 


