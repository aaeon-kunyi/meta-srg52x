#
# SRG-335x Debian Buster
#
# Copyright (c) LYD/AAEON, 2020
#
# Authors:
#   KunYi <kunyi.chen@gmail.com>
#
# SPDX-License-Identifier: MIT
#
# for real-time
# Linux RT Kernel 4.19.94
#
require recipes-kernel/linux/linux-custom.inc

DESCRIPTION = "Linux Kernel for SRG-3352x"
SECTION = "kernel"
MAINTAINER = "KunYi <kunyi.chen@gmail.com>"

KBUILD_DEPENDS += "lzop:native"

SRCBRANCH = "srg52_dev"

SRCREV = "344b98d854dfa49803a36c6a1aa2d8a7c44798ca"
KERNEL_REV = "344b98d854dfa49803a36c6a1aa2d8a7c44798ca"
KERNEL_DEFCONFIG = "srg52_defconfig"

SRC_URI += "https://github.com/aaeon-kunyi/am335x-kernel/archive/v1.0_beta06.tar.gz"
SRC_URI += "file://srg52_defconfig"

SRC_URI[md5sum] = "a280cff2e509bcea3bd0835c43e7444d"
SRC_URI[sha256sum] = "4da8cb73f2e4add15a361feb485db6133c824b18bfe0990c6abaa40c13bc1936"


S = "${WORKDIR}/am335x-kernel-1.0_beta06"
