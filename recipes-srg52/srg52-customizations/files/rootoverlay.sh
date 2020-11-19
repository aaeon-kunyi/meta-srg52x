#!/bin/sh -e
#
# This script is run inside of the initramfs environment during the
# system boot process.  It is installed there by 'update-initramfs'.
# The # package that owns it may opt to install it in an appropriate
# location under "/usr/share/initramfs-tools/scripts/".
#
# see initramfs-tools(7) for more details.

#
# List the soft prerequisites here.  This is a space separated list of
# names, of scripts that are in the same directory as this one, that
# must be run before this one can be.
#
PREREQ=""

prereqs()
{
	echo "$PREREQ"
}

case $1 in
# get pre-requisites
prereqs)
	prereqs
	exit 0
	;;
esac

. /scripts/functions

for CMD_PARAM in $(cat /proc/cmdline); do
	case ${CMD_PARAM} in
		wipedata=*)
		FACTORY_RESET=${CMD_PARAM#factoryreset=}
		;;
	esac
done

case $ROOT in
	/dev/mmcblk0*)
		echo " run on SD card"
		unset runOverlay
		;;
	/dev/mmcblk1*)
		echo " run on EMMC"
		runOverlay=yes
		;;
esac

if [ "x$runOverlay" = "x" ]; then
	# echo "no runOverlay"
	exit 0
fi

modprobe -qb overlay
if [ $? -ne 0 ]; then
	log_failure_msg "rootOverlay ERROR 1: missing kernel module 'overlay'"
	exit 0
fi

[ -d /overlay ] || mkdir -p /overlay
if [ $? -ne 0 ]; then
	log_failure_msg "rootOverlay ERROR 2: mkdir /overlay folder"
	exit 0
fi

mount -t tmpfs tmpfs /overlay
if [ $? -ne 0 ]; then
	log_failure_msg "rootOverlay ERROR 3: fail on create /overlay "
	exit 0
fi

OVER_LOWER=/overlay/lower
OVER_BLK=/overlay/blk
OVER_UPPER=/overlay/blk/upper
OVER_WORK=/overlay/blk/work

[ -d $OVER_LOWER ] || mkdir -p $OVER_LOWER
if [ $? -ne 0 ]; then
	log_failure_msg "rootOverlay ERROR 4: mkdir lower folder"
	exit 0
fi

[ -d $OVER_BLK ] || mkdir -p $OVER_BLK
if [ $? -ne 0 ]; then
	log_failure_msg "rootOverlay ERROR 5: mkdir blk folder"
	exit 0
fi

# mount data partition
mount -n -t ext4 /dev/mmcblk1p4 ${OVER_BLK}
if [ $? -ne 0 ]; then
	log_failure_msg "rootOverlay ERROR 6: mount data partition"
	exit 0
fi

[ -d $OVER_UPPER ] || mkdir -p $OVER_UPPER
if [ $? -ne 0 ]; then
	log_failure_msg "rootOverlay ERROR 7: mkdir upper folder"
	exit 0
fi

[ -d $OVER_WORK ] || mkdir -p $OVER_WORK
if [ $? -ne 0 ]; then
	log_failure_msg "rootOverlay ERROR 8: mkdir work folder"
	exit 0
fi

mount -n -o move ${rootmnt} /overlay/lower
mount -t overlay -o lowerdir=${OVER_LOWER},upperdir=${OVER_UPPER},workdir=${OVER_WORK} overlay ${rootmnt}

exit 0
