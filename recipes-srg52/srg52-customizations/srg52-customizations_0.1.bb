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
	file://fw_env.config		\
	file://issue			\
	file://issue.net		\
	file://motd			\
	file://initramfs.fsck.hook	\
	file://rootoverlay.sh		\
	file://scripts/tools		\
	file://automount/		\
	"

DEPENDS += "sshd-regen-keys"

DEBIAN_DEPENDS = " \
	ifupdown, isc-dhcp-client, net-tools, iputils-ping, ssh, sshd-regen-keys, hostapd"

do_install() {
	install -v -d ${D}/opt/scripts/tools
	install -m 0755 -d ${D}/opt/scripts
	install -v -m 755 ${WORKDIR}/scripts/tools/srg3352c_emmc_flasher.sh	${D}/opt/scripts/tools

	# for access environment variables of u-boot
	install -v -d ${D}/etc/
	install -v -m 644 ${WORKDIR}/fw_env.config ${D}/etc/

	# for local & remote login issue
	install -v -d ${D}/opt/srg52/etc/issue/
	install -v -m 644 ${WORKDIR}/issue	${D}/opt/srg52/etc/issue/
	install -v -m 644 ${WORKDIR}/issue.net	${D}/opt/srg52/etc/issue/
	install -v -m 644 ${WORKDIR}/motd	${D}/opt/srg52/etc/issue/

	# add scripts for initramfs
	SCRIPTS=${D}/etc/initramfs-tools/scripts/init-bottom
	install -v -d ${SCRIPTS}
	install -m 0755 -d ${SCRIPTS}
	install -m 0740 ${WORKDIR}/rootoverlay.sh ${SCRIPTS}

	# add hooks for initramfs
	HOOKS=${D}/etc/initramfs-tools/hooks
	install -v -d ${HOOKS}
	install -m 0755 -d ${HOOKS}
	install -m 0740 ${WORKDIR}/initramfs.fsck.hook	${HOOKS}/fsck.hook

	# automount
	# install -v -d ${D}/etc/udev/rules.d/
	# install -m 644 ${WORKDIR}/automount/automount.rules ${D}/etc/udev/rules.d
	# install -v -d ${D}/etc/udev/scripts/
	# install -m 0755 -d ${D}/etc/udev/scripts/
	# install -m 755 ${WORKDIR}/automount/srg52-automount.sh ${D}/etc/udev/scripts
	install -v -d ${D}/lib/udev/rules.d/
	install -m 644 ${WORKDIR}/automount/media-automount.rules ${D}/lib/udev/rules.d/99-media-automount.rules

	install -v -d ${D}/lib/systemd/system/
	install -m 644 ${WORKDIR}/automount/media-automount@.service ${D}/lib/systemd/system/
	install -v -d ${D}/usr/bin
	install -m 755 ${WORKDIR}/automount/umount_dmenu	${D}/usr/bin/umount_dmenu
	install -m 755 ${WORKDIR}/automount/media-automount	${D}/usr/bin/media-automount
}

addtask do_install after do_transform_template
