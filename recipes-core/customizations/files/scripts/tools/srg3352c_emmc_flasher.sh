#!/bin/bash -e
#
# Copyright (c) 2013-2015 Robert Nelson <robertcnelson@gmail.com>
# Portions copyright (c) 2014 Charles Steinkuehler <charles@steinkuehler.net>
# Copyright (c) 2020 LYD/AAEON, kunyi <kunyi.chen@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#This script assumes, these packages are installed, as network may not be setup
#dosfstools initramfs-tools rsync u-boot-tools

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

unset boot_drive
boot_drive=$(LC_ALL=C lsblk -l | grep "/" | awk '{print $1}')

if [ "x${boot_drive}" = "x" ] ; then
	echo "Error: script halting, system unrecognized..."
	exit 1
fi

if [ "x${boot_drive}" = "xmmcblk1p2" ] ; then
	echo "Error: script halting, only support from SD card to eMMC..."
	exit 1
fi

if [ "x${boot_drive}" = "xmmcblk0p2" ] ; then
	source="/dev/mmcblk0"
	destination="/dev/mmcblk1"
fi

echo "-------------------------"
echo "boot drive: ${boot_drive}"
echo "-------------------------"

flush_cache () {
	sync
	blockdev --flushbufs ${destination}
}

write_failure () {
	echo "writing to [${destination}] failed..."

	[ -e /proc/$CYLON_PID ]  && kill $CYLON_PID > /dev/null 2>&1

	if [ -e /sys/class/leds/srt3352\:led1/trigger ] ; then
		echo heartbeat > /sys/class/leds/srt3352\:led1/trigger
		echo heartbeat > /sys/class/leds/srt3352\:led2/trigger
		echo heartbeat > /sys/class/leds/srt3352\:led3/trigger
		echo heartbeat > /sys/class/leds/srt3352\:led4/trigger
	fi
	echo "-----------------------------"
	flush_cache
	umount ${destination}p1 || true
	umount ${destination}p2 || true	
	exit
}

check_running_system () {
	echo "-----------------------------"
	echo "debug copying: [${source}] -> [${destination}]"
	lsblk
	echo "-----------------------------"

	if [ ! -b "${destination}" ] ; then
		echo "Error: [${destination}] does not exist"
		write_failure
	fi
}

cylon_leds () {
	if [ -e /sys/class/leds/srt3352\:led1/trigger ] ; then
		BASE=/sys/class/leds/srt3352\:led
		echo none > ${BASE}1/trigger
		echo none > ${BASE}2/trigger
		echo none > ${BASE}3/trigger
		echo none > ${BASE}4/trigger

		STATE=1
		while : ; do
			case $STATE in
			1)	echo 255 > ${BASE}1/brightness
				echo 0   > ${BASE}2/brightness
				STATE=2
				;;
			2)	echo 255 > ${BASE}2/brightness
				echo 0   > ${BASE}1/brightness
				STATE=3
				;;
			3)	echo 255 > ${BASE}3/brightness
				echo 0   > ${BASE}2/brightness
				STATE=4
				;;
			4)	echo 255 > ${BASE}4/brightness
				echo 0   > ${BASE}3/brightness
				STATE=5
				;;
			5)	echo 255 > ${BASE}3/brightness
				echo 0   > ${BASE}4/brightness
				STATE=6
				;;
			6)	echo 255 > ${BASE}2/brightness
				echo 0   > ${BASE}3/brightness
				STATE=1
				;;
			*)	echo 255 > ${BASE}1/brightness
				echo 0   > ${BASE}2/brightness
				STATE=2
				;;
			esac
			sleep 0.1
		done
	fi
}

update_boot_files () {
	return
	#We need an initrd.img to find the uuid partition
	#update-initramfs -u -k $(uname -r)
}

fdisk_toggle_boot () {
	# enable partition 2 & disable partition 1
	fdisk ${destination} <<-__EOF__
	a
	2
	a
	1
	w
	__EOF__
	flush_cache
}

format_root () {
	mkfs.ext4 ${destination}p2 -L rootfs
	flush_cache
}

partition_drive () {
	flush_cache

	NUM_MOUNTS=$(mount | grep -v none | grep "${destination}" | wc -l)

	for ((i=1;i<=${NUM_MOUNTS};i++))
	do
		DRIVE=$(mount | grep -v none | grep "${destination}" | tail -1 | awk '{print $1}')
		umount ${DRIVE} >/dev/null 2>&1 || umount -l ${DRIVE} >/dev/null 2>&1 || write_failure
	done

	# erase bootloader
	flush_cache
	dd if=/dev/zero of=${destination} bs=1M count=8
	sync
	dd if=${destination} of=/dev/null bs=1M count=8
	sync
	flush_cache

	# erase root filesystem
	flush_cache
	dd if=/dev/zero of=${destination} bs=1M seek=127 count=8
	sync
	dd if=${destination} of=/dev/null bs=1M seek=127 count=8
	sync
	flush_cache

	#128Mb reserved formatted boot partition
	LC_ALL=C sfdisk --force "${destination}" <<-__EOF__
		1,128M,0x83,*
		,,,-
	__EOF__

	flush_cache
	fdisk_toggle_boot
	flush_cache
	format_root
}

copy_boot () {
	echo "write bootloader into EMMC..."
	dd if=/usr/lib/u-boot/srg-3352c/MLO of=${destination} bs=128k seek=1 status=progress conv=fsync || write_failure
	dd if=/usr/lib/u-boot/srg-3352c/u-boot.img of=${destination} bs=384k seek=1 status=progress conv=fsync || write_failure
}

copy_rootfs () {
	mkdir -p /tmp/rootfs/ || true
	mount ${destination}p2 /tmp/rootfs/ -o async,noatime

	echo "rsync: / -> /tmp/rootfs/"
	rsync -aAX /* /tmp/rootfs/ --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found,/boot/*,/lib/modules/*} || write_failure
	flush_cache

	#ssh keys will now get regenerated on the next bootup
	touch /tmp/rootfs/etc/ssh/ssh.regenerate
	flush_cache
	OLDPWD=$PWD
	cd /tmp/rootfs/etc/systemd/system
	ln -s /lib/systemd/system/sshd-regen-keys.service sshd-regen-keys.service
	cd $OLDPWD
	unset OLDPWD

	mkdir -p /tmp/rootfs/lib/modules/$(uname -r)/ || true

	echo "rsync: /lib/modules/$(uname -r)/ -> /tmp/rootfs/lib/modules/$(uname -r)/"
	rsync -aAX /lib/modules/$(uname -r)/* /tmp/rootfs/lib/modules/$(uname -r)/ || write_failure
	flush_cache

	echo "rsync: /boot/ -> /tmp/rootfs/boot/"
	mkdir -p /tmp/rootfs/boot/ || true
	rsync -aAIX  /boot/* /tmp/rootfs/boot/ --exclude=boot.scr || write_failure
	flush_cache

	unset boot_uuid
	boot_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value ${destination}p2)
	if [ "${boot_uuid}" ] ; then
		boot_uuid="UUID=${boot_uuid}"
	else
		boot_uuid="${source}p1"
	fi

	echo "Generating: /etc/fstab"
	echo "# /etc/fstab: static file system information." > /tmp/rootfs/etc/fstab
	echo "#" >> /tmp/rootfs/etc/fstab
	echo "${root_uuid}  /  ext4  noatime,errors=remount-ro  0  1" >> /tmp/rootfs/etc/fstab
	echo "debugfs  /sys/kernel/debug  debugfs  defaults  0  0" >> /tmp/rootfs/etc/fstab
	cat /tmp/rootfs/etc/fstab
	update_boot_script

	flush_cache
	umount /tmp/rootfs/ || umount -l /tmp/rootfs/ || write_failure

	#https://github.com/beagleboard/meta-beagleboard/blob/master/contrib/bone-flash-tool/emmc.sh#L158-L159
	# force writeback of eMMC buffers
	dd if=${destination} of=/dev/null count=100000

	[ -e /proc/$CYLON_PID ]  && kill $CYLON_PID

	if [ -e /sys/class/leds/srt3352\:led1/trigger ] ; then
		echo default-on > /sys/class/leds/srt3352\:led1/trigger
		echo default-on > /sys/class/leds/srt3352\:led2/trigger
		echo default-on > /sys/class/leds/srt3352\:led3/trigger
		echo default-on > /sys/class/leds/srt3352\:led4/trigger
	fi

	echo ""
	echo "This script has now completed it's task"
	echo "-----------------------------"
	echo "Note: Actually unpower the board, a reset [sudo reboot] is not enough."
	echo "-----------------------------"

	echo "Shutting Down..."
	sync
	halt
}

update_boot_script() {
	echo "Update boot script into rootfs"
	if [ -f /etc/default/u-boot-script ]; then
		. /etc/default/u-boot-script
	fi

	BOOT_CMD=$(mktemp)
	KERNEL_VERSION=$(linux-version list | linux-version sort --reverse | head -1)

	KERNEL_FILE="vmlinuz"
	BOOT="bootz"

	echo "${SCRIPT_PREPEND}" >> ${BOOT_CMD}
	# KERNEL_ARGS definition in /etc/default/u-boot-script
	# echo "setenv bootargs ${KERNEL_ARGS}" >> ${BOOT_CMD}
	echo "setenv distro_bootpart 2" >> ${BOOT_CMD}

	echo "load \${devtype} \${devnum}:\${distro_bootpart} \${fdt_addr_r}" \
		"/usr/lib/linux-image-${KERNEL_VERSION}/\${fdtfile}" >> ${BOOT_CMD}

	echo "load \${devtype} \${devnum}:\${distro_bootpart} \${kernel_addr_r}" \
		"/boot/${KERNEL_FILE}-${KERNEL_VERSION}" >> ${BOOT_CMD}
	# >>> debugging
	echo "setenv bootfile ${KERNEL_FILE}-${KERNEL_VERSION}" >> ${BOOT_CMD}
	echo "setenv fdtfile ../usr/lib/linux-image-${KERNEL_VERSION}/am335x-srg3352c.dtb" >> ${BOOT_CMD}
	# <<< debugging

	case "${NO_INITRD}" in
	yes|1)
		INITRD_ADDR="-"
		;;
	*)
		echo "load \${devtype} \${devnum}:\${distro_bootpart}" \
			"\${ramdisk_addr_r} /boot/initrd.img-${KERNEL_VERSION}" \
			>> ${BOOT_CMD}
		INITRD_ADDR="\${ramdisk_addr_r}:\${filesize}"
		;;
	esac

	if [ -n "${OVERLAYS}" ]; then
		echo "fdt addr \${fdt_addr_r}" >> ${BOOT_CMD}
		# grant 1 MB to combined device tree
		echo "fdt resize 0x100000" >> ${BOOT_CMD}
		echo "setexpr overlay_addr_r \${fdt_addr_r} + 0x100000" >> ${BOOT_CMD}
		for OVERLAY in ${OVERLAYS}; do
			if ! echo $OVERLAY | grep -q "^/"; then
				OVERLAY_PATH=/usr/lib/linux-image-${KERNEL_VERSION}/
			fi
			echo "load \${devtype} \${devnum}:${ROOT_PARTITION}" \
				"\${overlay_addr_r} ${OVERLAY_PATH}${OVERLAY}" \
				>> ${BOOT_CMD}
			echo "fdt apply \${overlay_addr_r}" >> ${BOOT_CMD}
		done
	fi

	# for fixup bootargs
	echo "run args_mmc" >> ${BOOT_CMD}

	echo "${BOOT} \${kernel_addr_r} ${INITRD_ADDR} \${fdt_addr_r}" >> ${BOOT_CMD}

	mkimage -T script -A invalid -C none -d ${BOOT_CMD} /tmp/rootfs/boot/boot.scr > /dev/null

	rm ${BOOT_CMD}
}

check_running_system
cylon_leds & CYLON_PID=$!
update_boot_files
partition_drive
copy_boot
copy_rootfs