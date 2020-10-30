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

inherit image
inherit image_uuid
ISAR_RELEASE_CMD = "git -C ${LAYERDIR_srg52-buster} describe --tags --dirty --always --match 'v[0-9].[0-9]*'"
DESCRIPTION = "SRG-3352x Debian Buster image"

IMAGE_INSTALL += "customizations"
# IMAGE_INSTALL += "initramfs-fsck-hook-ext4"

# some script need this package
IMAGE_PREINSTALL += "bsdmainutils rsync"

# for swupdate
SWU_DESCRIPTION ??= "swupdate"
include ${SWU_DESCRIPTION}.inc
