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

SRCREV = "f4e286d96542b3c8d52efb85eea8b0b823a3e5e1"
KERNEL_REV = "f4e286d96542b3c8d52efb85eea8b0b823a3e5e1"
KERNEL_DEFCONFIG = "srg52_defconfig"

SRC_URI += "https://github.com/KunYi/am33xx-kernel-dev/archive/${SRCBRANCH}.zip"
SRC_URI += "file://srg52_defconfig"

SRC_URI[md5sum] = "a5f0be0b919ce4d7e05772991d2aa022"
SRC_URI[sha256sum] = "60f5e0bfad3fdc23b5bcad7fa96671986df05cb11a04bf974efd5160d215a9bf"

S = "${WORKDIR}/am33xx-kernel-dev-srg52_dev"
