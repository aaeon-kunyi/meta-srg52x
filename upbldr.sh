#!/bin/bash -x


uboot_src="./build/tmp/work/srg52-buster-armhf/u-boot-srg-3352c/2019.01-r23/git"
uboot_dest="/media/$USER/platform/usr/lib/u-boot/srg-3352c/"

if [ -f ${uboot_src}/MLO ]; then
	echo "will update MLO & u-boot.img --> [$1]"
	if [ -d ${uboot_dest} ]; then
		echo "found SD card, will update u-boot.img & MLO"
		sudo cp -fv ${uboot_src}/MLO ${uboot_dest}
		sudo cp -fv ${uboot_src}/u-boot.img ${uboot_dest}
		sudo cp -fv ${uboot_src}/u-boot.elf ${uboot_dest}
		sync
	fi

	if [ -b $1 ]; then
		sudo umount $1
		sudo dd if=${uboot_src}/MLO of=$1 bs=128K seek=1 status=progress conv=fsync 
		sudo dd if=${uboot_src}/u-boot.img of=$1 bs=384K seek=1 status=progress conv=fsync
		sudo dd if=$1 of=/dev/null count=2000000
		sync
	fi
fi

