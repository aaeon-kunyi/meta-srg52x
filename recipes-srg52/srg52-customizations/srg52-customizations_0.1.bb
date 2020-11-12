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
	"

DEBIAN_DEPENDS += "hostapd"

do_install() {

	# add hooks for initramfs
	HOOKS=${D}/etc/initramfs-tools/hooks
	install -m 0755 -d ${HOOKS}
	install -m 0740 ${WORKDIR}/initramfs.fsck.hook	${HOOKS}/fsck.hook
}

addtask do_install after do_transform_template
