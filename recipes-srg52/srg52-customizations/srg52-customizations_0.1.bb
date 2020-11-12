#
# SRG-335x Debian Buster customizations
#
# Copyright (c) LYD/AAEON, 2020
#
# Authors:
#  KunYi <kunyi.chen@gmail.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

DESCRIPTION = "SRG-335x customizations"

SRC_URI = " \
	file://postinst			\
	file://initramfs.fsck.hook	\
	file://scripts/tools		\
	"

DEPENDS += "sshd-regen-keys"

DEBIAN_DEPENDS = " \
	ifupdown, isc-dhcp-client, net-tools, iputils-ping, ssh, sshd-regen-keys, hostapd"

do_install() {
	install -v -d ${D}/opt/scripts/tools
	install -m 0755 -d ${D}/opt/scripts
	install -v -m 755 ${WORKDIR}/scripts/tools/srg3352c_emmc_flasher.sh	${D}/opt/scripts/tools

	# add hooks for initramfs
	HOOKS=${D}/etc/initramfs-tools/hooks
	install -m 0755 -d ${HOOKS}
	install -m 0740 ${WORKDIR}/initramfs.fsck.hook	${HOOKS}/fsck.hook
}

addtask do_install after do_transform_template
