#
# Copyright (c) LYD/AAEON, 2020
#
# SPDX-License-Identifier: MIT

inherit dpkg

DESCRIPTION = "SRG-3352x system configuration tool"
MAINTAINER = "kunyi <kunyi.chen@gmail.com>"
DEBIAN_DEPENDS = "cmake"

SRC_URI = "file://src"

S = "${WORKDIR}/src"

do_prepare_build[cleandirs] += "${S}/debian"

do_prepare_build() {
    deb_debianize
    sed -i -e 's/Section: misc/Section: utils/g' ${S}/debian/control
}