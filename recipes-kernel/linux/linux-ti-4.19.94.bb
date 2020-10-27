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

SRCBRANCH = "processor-sdk-linux-4.19.y"
SRCREV = "be5389fd85b69250aeb1ba477447879fb392152f"
# Linux Kernel 4.19.94

SRC_URI += "git://git.ti.com/processor-sdk/processor-sdk-linux.git;protocol=git;branch=${SRCBRANCH}"
