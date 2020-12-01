#
# Copyright (c) LYD/AAEON, 2020
#
# SPDX-License-Identifier: MIT

inherit dpkg

DESCRIPTION = "Tools for SRG-3352x Expansion Board Mode A"
MAINTAINER = "kunyi <kunyi.chen@gmail.com>"

DEBIAN_DEPENDS = "libgpiod2"
DEBIAN_BUILD_DEPENDS = "cmake, libgpiod-dev"

SRC_URI = "file://src"

S = "${WORKDIR}/src"

do_prepare_build[cleandirs] += "${S}/debian"

do_prepare_build() {
    deb_debianize
}
