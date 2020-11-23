#
# SRG-335x Debian Buster test script
#
# Copyright (c) LYD/AAEON, 2020
#
# Authors:
#  KunYi <kunyi.chen@gmail.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

DESCRIPTION = "SRG-335x test script"

SRC_URI = " \
	file://postinst			\
	file://srg52-test.tgz		\
	"
DEBIAN_DEPENDS = " bash "

do_install() {
	install -v -d ${D}/root/test
	cp -rfv ${WORKDIR}/test/* ${D}/root/test
}

addtask do_install after do_transform_template
