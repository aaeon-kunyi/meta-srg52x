#
# TI CM3 Power Management firmware package for AM335x
#
# Copyright (c) LYD/AAEON, 2020
#
# Authors:
#   KunYi <kunyi.chen@gmail.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

DESCRIPTION = "Ti AM335x Power Management firmware package"

SRC_URI = "                                         \
    file://postinst                                 \
    file://am335x-pm-firmware.hook                  \
    file://am335x-bone-scale-data.bin               \
    file://am335x-evm-scale-data.bin                \
    file://am335x-pm-firmware.elf                   \
    "

do_install() {
    # add patch for local to /usr/share/secure boot
    TARGET=${D}/lib/firmware
    install -m 0755 -d ${TARGET}
    install -m 0644 ${WORKDIR}/am335x-bone-scale-data.bin ${TARGET}/am335x-bone-scale-data.bin
    install -m 0644 ${WORKDIR}/am335x-evm-scale-data.bin ${TARGET}/am335x-evm-scale-data.bin    
    install -m 0644 ${WORKDIR}/am335x-pm-firmware.elf ${TARGET}/am335x-pm-firmware.elf

    # add hooks for initramfs
    HOOKS=${D}/etc/initramfs-tools/hooks
    install -m 0755 -d ${HOOKS}
    install -m 0740 ${WORKDIR}/am335x-pm-firmware.hook ${HOOKS}/am335x-pm-firmware.hook
}

addtask do_install after do_transform_template
