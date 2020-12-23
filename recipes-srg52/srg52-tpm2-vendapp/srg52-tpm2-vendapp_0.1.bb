#
# SRG-3352x Debian Buster TPM vendor application
#
# Copyright (c) LYD/AAEON, 2020
#
# Authors:
#  KunYi <kunyi.chen@gmail.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

DESCRIPTION = "SRG-3352x TPM vendor application"

MAINTAINER = "kunyichen@sparktech.io"

DEBIAN_DEPENDS = "apt (>= 0.4.2), libc6:armhf"

SRC_URI = "			\
	file://aSkCmd		\
	file://test_tpm2.sh	\
	file://rules		\
	"

do_install() {
	install -v -d ${D}/root
	install -v -m 775 ${WORKDIR}/aSkCmd ${D}/root/
	install -v -m 775 ${WORKDIR}/test_tpm2.sh ${D}/root/
}
