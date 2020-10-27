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
SRCREV = "9226678c3970041457ac8eaac66ce20d8dc768c5"
KERNEL_REV = "9226678c3970041457ac8eaac66ce20d8dc768c5"
KERNEL_DEFCONFIG = "srg52_defconfig"
SRC_URI += "https://github.com/KunYi/am33xx-kernel-dev/archive/${SRCBRANCH}.zip"
SRC_URI += "file://srg52_defconfig"
SRC_URI[sha256sum] = "f9008864ec2ddca6fd22d4df9cbe9eb01858e8bdfff08b409cada0155ba79d26"

S = "${WORKDIR}/am33xx-kernel-dev-srg52_dev"