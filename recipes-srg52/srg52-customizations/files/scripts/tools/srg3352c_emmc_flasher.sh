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

unset root_drive
root_drive=$(LC_ALL=C lsblk -l | grep "/" | awk '{print $1}')

if [[ "x${root_drive}" = "x" ]] ; then
	echo "Error: script halting, system unrecognized..."
	exit 1
fi

if [[ "x${root_drive}" = "xmmcblk1p"* ]] ; then
	echo "Error: script halting, only support from SD card to eMMC..."
	exit 1
fi

if [[ "x${root_drive}" == "xmmcblk0p"* ]] ; then
	source="/dev/mmcblk0"
	destination="/dev/mmcblk1"
fi

echo "--------------------------------"
echo "rootfs drive: ${root_drive}"
echo "--------------------------------"

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
	umount ${destination}p3 || true
	umount ${destination}p4 || true
	exit
}

check_running_system () {
	echo "--------------------------------------------"
	echo "copying: [${source}] -> [${destination}]"
	lsblk
	echo "--------------------------------------------"

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

format_partitions () {
	echo "format partitions"
	flush_cache
	sync
	mkfs.ext4 -qF ${destination}p1 -L reserved
	mkfs.ext4 -qF ${destination}p2 -L boot
	mkfs.ext4 -qF ${destination}p3 -L rootfs
	mkfs.ext4 -qF ${destination}p4 -L data
	flush_cache
	sync
}

partition_drive () {
	flush_cache

	NUM_MOUNTS=$(mount | grep -v none | grep "${destination}" | wc -l)

	for ((i=1;i<=${NUM_MOUNTS};i++))
	do
		DRIVE=$(mount | grep -v none | grep "${destination}" | tail -1 | awk '{print $1}')
		umount ${DRIVE} >/dev/null 2>&1 || umount -l ${DRIVE} >/dev/null 2>&1 || write_failure
	done

	# erase partition filesystem information
	flush_cache
	echo "erase all data of EMMC"
	dd if=/dev/zero of=${destination} bs=4K count=200 > /dev/null 2>&1  || true
	dd if=/dev/zero of=${destination} bs=1M seek=4 count=1 > /dev/null 2>&1  || true
	dd if=/dev/zero of=${destination} bs=1M seek=68 count=1 > /dev/null 2>&1 || true
	dd if=/dev/zero of=${destination} bs=1M seek=132 count=1 > /dev/null 2>&1  || true
	dd if=/dev/zero of=${destination} bs=1M seek=2180 count=1 > /dev/null 2>&1  || true
	sync
	flush_cache

	# GPT/EFI Partition
	# 8192 sector: 8192*512B, 4MB for bootloader/environments
	# p1: 64MB reserved partition
	# p2: 64MB boot partition, * boot active
	# p3: 2GB, root filesystem,
	# p4: another for user data
	#
	# except the below configuration
	# --------------------------------------------------------------------------------------------
	# Device	 Boot	Start		End		Sectors		Size	Id	Type
	# /dev/mmcblk1p1	   8192		  139263	   131072	 64M	83	Linux
	# /dev/mmcblk1p2 *	 139264		  270335	   131072	 64M	83	Linux
	# /dev/mmcblk1p3	 270336		 4464639	  4194304	  2G	83	Linux
	# /dev/mmcblk1p3	4464640		15269887	 10805248	5.2G	83	Linux
	# --------------------------------------------------------------------------------------------
	# >>>--------------- for MBR ----------------------------------
	#LC_ALL=C sfdisk --force "${destination}" <<-__EOF__
	#	8192,	64M, ,
	#	139264, 64M, , *
	#	270336,2048M, ,
	#	4464640,,,-
	#__EOF__
	# <<<----------------------------------------------------------
	# >>>--------------- for GPT/EFI ------------------------------
	LC_ALL=C sgdisk --zap-all --clear "${destination}" > /dev/null 2>&1 || true
	sync
	flush_cache
	dd if=${destination} of=/dev/null bs=1M count=1 > /dev/null 2>&1 || true

	LC_ALL=C sgdisk -n 1:8192:+64MiB -t 1:8300 -c 1:"reserved" -u 1:8DA63339-0007-60C0-C4366-083AC8230908 "${destination}" > /dev/null 2>&1 || true
	sync
	flush_cache
	dd if=${destination} of=/dev/null bs=1M count=1 > /dev/null 2>&1 || true

	LC_ALL=C sgdisk -n 2::+64MiB -t 2:8300 -c 2:"boot" -A 2:set:2 -u 2:BC13C2FF-59E6-4262-A352-B275FD6F7172 "${destination}" > /dev/null 2>&1 || true
	sync
	flush_cache
	dd if=${destination} of=/dev/null bs=1M count=1 > /dev/null 2>&1 || true

	LC_ALL=C sgdisk -n 3::+2GiB -t 3:8300 -c 3:"rootfs" -u 3:69DAD710-2CE4-4E3C-B16C-21A1DD49ABED3 "${destination}" > /dev/null 2>&1 || true
	sync
	flush_cache
	dd if=${destination} of=/dev/null bs=1M count=1 > /dev/null 2>&1 || true

	LC_ALL=C sgdisk -n 4:: -t 4:8300 -c 4:"data" -u 4:933AC7E1-2EB4-4F13-B844-0E14E2AEF9915 "${destination}" > /dev/null 2>&1 || true
	sync
	flush_cache
	dd if=${destination} of=/dev/null bs=1M count=1 > /dev/null 2>&1 || true
	# for boot flags, bootloader need this
	# LC_ALL=C sgdisk -A 2:set:2 "${destination}"
	# <<<----------------------------------------------------------
	sync
	flush_cache
	format_partitions
}

generation_fstab () {
	echo "Generating: /etc/fstab"
	echo "# /etc/fstab: static file system information." > /tmp/rootfs/etc/fstab
	echo "#" >> /tmp/rootfs/etc/fstab
	echo "# ${root_uuid}		/			ext4		noatime,errors=remount-ro			0 1" >> /tmp/rootfs/etc/fstab
	echo "${boot_uuid}		/boot			ext4		noatime,errors=remount-ro			0 2" >> /tmp/rootfs/etc/fstab
	echo "proc			/proc			proc		defaults					0 0" >> /tmp/rootfs/etc/fstab
	echo "sysfs			/sys			sysfs		rw,nosuid,nodev,noexec,relatime			0 0" >> /tmp/rootfs/etc/fstab
	echo "devpts			/dev/pts		devpts		rw,nosuid,noexec,relatime,mode=0620,gid=5	0 0" >> /tmp/rootfs/etc/fstab
	echo "tmpfs			/run			tmpfs		mode=0755,nodev,nosuid,strictatime		0 0" >> /tmp/rootfs/etc/fstab
	echo "tmpfs			/var/volatile		tmpfs		defaults					0 0" >> /tmp/rootfs/etc/fstab
	echo "tmpfs			/dev/shm		tmpfs		defaults					0 0" >> /tmp/rootfs/etc/fstab
	echo "debugfs			/sys/kernel/debug	debugfs		defaults					0 0" >> /tmp/rootfs/etc/fstab
	cat /tmp/rootfs/etc/fstab
}

copy_boot () {
	echo "write bootloader into EMMC..."
	dd if=/usr/lib/u-boot/srg-3352c/MLO of=${destination} bs=128k seek=1 status=progress conv=fsync || write_failure
	dd if=/usr/lib/u-boot/srg-3352c/u-boot.img of=${destination} bs=384k seek=1 status=progress conv=fsync || write_failure
}

copy_rootfs () {
	local src_boot=${source}p1
	local dst_reserved=${destination}p1
	local dst_boot=${destination}p2
	local dst_root=${destination}p3

	mkdir -p /tmp/rootfs/ || true
	mount ${dst_root} /tmp/rootfs/ -o async,noatime

	mkdir -p /tmp/boot || true
	mount ${src_boot} /tmp/boot/ -o async,noatime

	mkdir -p /tmp/rootfs/boot/ || true
	mount ${dst_boot} /tmp/rootfs/boot -o async,noatime

	mkdir -p /tmp/rootfs/reserved/ || true
	mount  ${dst_reserved} /tmp/rootfs/reserved -o async,noatime

	echo "rsync: / -> /tmp/rootfs/"
	rsync -aAX /* /tmp/rootfs/ --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found,/reserved/*,/boot/*,/lib/modules/*} || write_failure
	flush_cache

	#ssh keys will now get regenerated on the next bootup
	touch /tmp/rootfs/etc/ssh/ssh.regenerate
	flush_cache

	# re-enable sshd-regen-keys
	OLDPWD=$PWD
	cd /tmp/rootfs/etc/systemd/system/sysinit.target.wants/
	ln -s /lib/systemd/system/sshd-regen-keys.service sshd-regen-keys.service
	cd $OLDPWD
	unset OLDPWD

	mkdir -p /tmp/rootfs/lib/modules/$(uname -r)/ || true

	echo "rsync: /lib/modules/$(uname -r)/ -> /tmp/rootfs/lib/modules/$(uname -r)/"
	rsync -aAX /lib/modules/$(uname -r)/* /tmp/rootfs/lib/modules/$(uname -r)/ || write_failure
	flush_cache

	echo "rsync: /tmp/boot/ -> /tmp/rootfs/boot/"
	rsync -aAIX  /tmp/boot/* /tmp/rootfs/boot/ --exclude={boot.scr,/lost+found} || write_failure
	flush_cache

	unset boot_uuid
	boot_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value ${dst_boot})
	unset root_uuid
	root_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value ${dst_root})
	if [ "${boot_uuid}" ]; then
		boot_uuid="UUID=${boot_uuid}"
	else
		boot_uuid="${dst_boot}"
	fi
	if [ "${root_uuid}" ]; then
		root_uuid="UUID=${root_uuid}"
	else
		root_uuid="${dst_root}"
	fi
	generation_fstab

	update_boot_script

	echo "rsync: boot partition -> /tmp/rootfs/reserved/"
	rsync -aAIX  /tmp/rootfs/boot/* /tmp/rootfs/reserved/ --exclude=lost+found/|| write_failure
	flush_cache

	flush_cache
	umount /tmp/boot || umount -l /tmp/boot || write_failure
	umount /tmp/rootfs/reserved || umount -l /tmp/rootfs/reserved || write_failure
	umount /tmp/rootfs/boot || umount -l /tmp/rootfs/boot || write_failure
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
	echo "run finduuid" >> ${BOOT_CMD}
	echo "setenv bootargs console=\${console} \${optargs} root=PARTUUID=\${uuid} rw rootfstype=\${mmcrootfstype}" >> ${BOOT_CMD}
	echo "load \${devtype} \${devnum}:\${distro_bootpart} \${fdt_addr_r}" \
		"/dtbs/\${fdtfile}" >> ${BOOT_CMD}
	echo "load \${devtype} \${devnum}:\${distro_bootpart} \${kernel_addr_r}" \
		"/${KERNEL_FILE}-${KERNEL_VERSION}" >> ${BOOT_CMD}

	case "${NO_INITRD}" in
	yes|1)
		INITRD_ADDR="-"
		;;
	*)
		echo "load \${devtype} \${devnum}:\${distro_bootpart}" \
			"\${ramdisk_addr_r} /initrd.img-${KERNEL_VERSION}" \
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
				OVERLAY_PATH=/dtbs/overlay/
			fi
			echo "load \${devtype} \${devnum}:\${distro_bootpart}" \
				"\${overlay_addr_r} ${OVERLAY_PATH}${OVERLAY}" \
				>> ${BOOT_CMD}
			echo "fdt apply \${overlay_addr_r}" >> ${BOOT_CMD}
		done
	fi

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
