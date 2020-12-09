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

SRCREV = "f4e286d96542b3c8d52efb85eea8b0b823a3e5e1"
KERNEL_REV = "f4e286d96542b3c8d52efb85eea8b0b823a3e5e1"
KERNEL_DEFCONFIG = "srg52_defconfig"

SRC_URI += "https://github.com/aaeon-kunyi/am335x-kernel/archive/${SRCBRANCH}.zip"
SRC_URI += "file://srg52_defconfig"

SRC_URI[md5sum] = "8e752d8defc9b1086ae211f43faa2737"
SRC_URI[sha256sum] = "a365e13ef4ebcf2f60ef7c1a74b36bf31d557abe72764d5ec539721b2017da47"

S = "${WORKDIR}/am335x-kernel-srg52_dev"
