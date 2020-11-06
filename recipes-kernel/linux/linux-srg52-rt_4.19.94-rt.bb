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

KBUILD_DEPENDS += "lzop"

SRCBRANCH = "srg52_dev"
SRCREV = "3e259b59a674ca7aa538d37fedbb6386b29d6c6f"
KERNEL_REV = "3e259b59a674ca7aa538d37fedbb6386b29d6c6f"
KERNEL_DEFCONFIG = "srg52_defconfig"
SRC_URI += "https://github.com/KunYi/am33xx-kernel-dev/archive/${SRCBRANCH}.zip"
SRC_URI += "file://srg52_defconfig"

SRC_URI[md5sum] = "93f2c5c32fc0bc309369fa53c3818dd6"
SRC_URI[sha256sum] = "81f86a414fee87bcc3cd725f2234c4781d5443eba9382a4dfa937596f8ed5f9a"

S = "${WORKDIR}/am33xx-kernel-dev-srg52_dev"