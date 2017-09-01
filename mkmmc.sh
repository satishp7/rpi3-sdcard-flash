#!/bin/bash
set -e
OUT=/dev/null


# max allow disk size is 9GB, change if high storage is used
MAX_ALLOWED_DISK_SIZE=9663676416

function usage()
{
cat <<EOF
Invoke "./mkmmc.sh" from your shell to set to format and prepare the sd card:
Arguments:
-d <device>                     ; device name e.g. /dev/sdcx
-and <android source>           ; location of boot directory
-kernel <kernel dir>            ; location of kernel dir
-out	<android out dir>       ; out directory path, should include product location
                                  if not set default location is ./out
EOF
}

function unset_var()
{
    unset SDDEV
    unset R_BOOT_DIR
    unset R_KERNEL_PATH
    unset R_DTB_PATH
	unset R_DTBO_PATH
    unset AND_OUT_DIR
    unset R_AND_DIR
    unset R_KERNEL_DIR
	unset AND_RAMDISK_IMG
	unset AND_SYSTEM_IMG
}

function validate_path()
{
	if [[ ! -d $R_AND_DIR || ! -d $R_KERNEL_DIR ]]
    then
        echo "Something wrong with paths, re-verify!!"
	    usage
	exit
    fi
    
    R_BOOT_DIR=${R_AND_DIR}/device/brcm/rpi3/boot
    echo "Boot dir:$R_BOOT_DIR"
    if [ ! -d $R_BOOT_DIR ]; then
        echo "Error: boot directory not present"
        exit
    fi

    R_KERNEL_PATH=${R_KERNEL_DIR}/arch/arm/boot/zImage
    R_DTB_PATH=${R_KERNEL_DIR}/arch/arm/boot/dts/bcm2710-rpi-3-b.dtb
    R_DTBO_PATH=${R_KERNEL_DIR}/arch/arm/boot/dts/overlays/vc4-kms-v3d.dtbo
    if [[ ! -f $R_KERNEL_PATH || ! -f $R_DTB_PATH || ! -f $R_DTBO_PATH ]]
    then
        echo "Error: kernel images are not present, make sure kernel is built"
        exit
    fi
    
    if [ -z $AND_OUT_DIR ]; then
        AND_OUT_DIR=${R_AND_DIR}/out/target/product/rpi3
        echo "Android out:$AND_OUT_DIR"
    fi
    AND_RAMDISK_IMG=${AND_OUT_DIR}/ramdisk.img
    AND_SYSTEM_IMG=${AND_OUT_DIR}/system.img
# AND_USERDATA_IMG=${AND_OUT_DIR}/userdata.img
    
    if [[ ! -f $AND_RAMDISK_IMG || ! -f $AND_SYSTEM_IMG ]]
    then
        echo "Error: android images are not present, make sure android is built"
        echo "$AND_RAMDISK_IMG"
        echo "$AND_SYSTEM_IMG"
        exit
    fi
}

############################################################################
# entry point of script: main
#############################################################################
unset_var

while [ $# -gt 0 ]; do
    case "$1" in
        -d)
        SDDEV=$2
        ;;
        -and)
        R_AND_DIR=$2
        ;;
        -kernel)
        R_KERNEL_DIR=$2
        ;;
        -out)
        R_AND_OUT_DIR=$2
        ;;
        -h|--help)
        usage
        return 0
        ;;
    esac
    shift
done

# validate paths
validate_path

DRIVE=$SDDEV
DEVICE=`basename $DRIVE`

# Simplistic sanity check to prevent selecting a larger device
# such as a secondary hard drive, or attached backup drive.
DISKSIZE=` fdisk -l $DRIVE | grep Disk | grep $DRIVE`
SIZE=`echo $DISKSIZE | awk '{print $5}'`
if [ $SIZE -gt $MAX_ALLOWED_DISK_SIZE ]
then
	echo ""
	echo "*** Warning! Device reports > MAX_ALLOWED_DISK_SIZE ($MAX_ALLOWED_DISK_SIZE). ***"
	echo "  $DISKSIZE"
	echo "Are you sure you selected the correct device? [y/n]"
	read ans
	if ! [[ $ans == 'y' ]]
	then
		exit
	fi
fi

for file in $(find /sys/block/$DEVICE/device/ /sys/block/$DEVICE/ -maxdepth 1 2>/dev/null \
 |egrep '(vendor|model|manfid|name|/size|/sys/block/[msh][mdr]./$|/sys/block/mmcblk./$)'|sort);
do [ -d $file ] && echo -e "\n  -- DEVICE $(basename $file) --" && continue;
grep -H . $file|sed -e 's|^/sys/block/||;s|/d*e*v*i*c*e*/*\(.*\):| \1 |'|awk '{if($2 == "size") {printf "%-3s %-6s: %d MB\n", $1,$2,(($3 * 512)/1048576)} else {printf "%-3s %-6s: ", $1,$2;for(i=3;i<NF;++i) printf "%s ",$i;print $(NF) };}';
done
echo "";

echo "[Unmounting all existing partitions on the device ]"

devices=`ls /sys/block/$DEVICE/$DEVICE* -d | sed "s^/sys/block/$DEVICE/^^"`
for f in $devices; do
	MOUNTCHECK=`mount | grep "^/dev/$f" | wc -l`
	if [[ $MOUNTCHECK = '1' ]]
	then
		MOUNTINFO=`mount | grep "^/dev/$f" | awk '{ print $1 " " $2 " " $3 " " $4 " " $5 }' `
		echo "  unmounting $f ($MOUNTINFO)"
		 umount /dev/$f
	fi
done
# umount $DRIVE

echo ""
echo "All data on $DRIVE now will be destroyed! Continue? [y/n]"
read ans
if ! [ $ans == 'y' ]
then
	exit
fi

echo "[Partitioning $DRIVE...]"

SIZE=` fdisk -l $DRIVE | grep Disk | awk '{print $5}'`
	 
echo DISK SIZE - $SIZE bytes
 
CYLINDERS=`echo $SIZE/255/63/512 | bc`
 
echo CYLINDERS - $CYLINDERS

 dd if=/dev/zero of=$DRIVE bs=1024 count=1024 &> $OUT

 parted --script $DRIVE \
    mklabel msdos \
    mkpart primary fat32 8MB 520MB \
    mkpart primary 520MB 1544MB \
    mkpart primary 1544MB 2056MB \
    mkpart primary 2056MB 2568MB

echo "[Partprobe $DRIVE...]"
 partprobe $DRIVE

if [ $DRIVE == '/dev/mmcblk0' ]
then
	PART='p'
else
	PART=''
fi

 dd if=/dev/zero of="${DRIVE}${PART}1" bs=512 count=1 &> $OUT
 dd if=/dev/zero of="${DRIVE}${PART}2" bs=512 count=1 &> $OUT
 dd if=/dev/zero of="${DRIVE}${PART}3" bs=512 count=1 &> $OUT
 dd if=/dev/zero of="${DRIVE}${PART}4" bs=512 count=1 &> $OUT

echo "[Making filesystems...]"

echo "[Formating boot...]"
 mkfs.vfat -F 32 -n boot "${DRIVE}${PART}1" &> $OUT
echo "[Formating system...]"
 mkfs.ext4 -L system "${DRIVE}${PART}2" &> $OUT
echo "[Formating cache...]"
 mkfs.ext4 -L cache "${DRIVE}${PART}3" &> $OUT
echo "[Formating userdata...]"
 mkfs.ext4 -L userdata "${DRIVE}${PART}4" &> $OUT

echo "[Copying files...]"
echo "[Copying boot...]"
 mount "${DRIVE}${PART}1" /mnt
 cp $R_AND_DIR/device/brcm/rpi3/boot/* /mnt/
 cp $R_AND_DIR/kernel/rpi/arch/arm/boot/zImage /mnt/
 cp $R_AND_DIR/kernel/rpi/arch/arm/boot/dts/bcm2710-rpi-3-b.dtb /mnt/
 mkdir -p /mnt/overlays
 cp $R_AND_DIR/kernel/rpi/arch/arm/boot/dts/overlays/vc4-kms-v3d.dtbo /mnt/overlays/vc4-kms-v3d.dtbo
 cp $AND_RAMDISK_IMG /mnt/

 umount "${DRIVE}${PART}1"

echo "[Copying system...]"
 mount "${DRIVE}${PART}2" /mnt
# dd if=$AND_SYSTEM_IMG of=${DRIVE}${PART}2 bs=1M
  cp -rf $AND_OUT_DIR/system/* /mnt/
 umount "${DRIVE}${PART}2"

echo "[Done]"
