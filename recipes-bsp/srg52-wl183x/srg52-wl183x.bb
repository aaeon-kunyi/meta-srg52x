#
# TI WL1831 Firmware package
#
# Copyright (c) LYD/AAEON, 2020
#
# Authors:
#   KunYi <kunyi.chen@gmail.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

DESCRIPTION = "SRG-3352C WL1831 Firmware package"

SRC_URI = "                                             \
    file://postinst                                     \
    file://firmware/regulatory.db                       \
    file://firmware/regulatory.db.p7s                   \
    file://firmware/ti-connectivity/wl18xx-fw-4.bin     \
    file://firmware/ti-connectivity/wl1271-nvs.bin      \
    file://firmware/ti-connectivity/wl18xx-conf.bin     \
    file://firmware/ti-connectivity/TIInit_11.8.32.bts  \
    file://btwilink-blacklist.conf                      \
    file://srg52c-wl18xx-wlan0                          \
    file://srg52c-wlan0.service                         \
    file://srg52c-bt-en                                 \
    file://srg52c-bluetooth.service                     \
    file://wl18xx-bts-firmware.hook                     \
    file://wl18xx-wlan-firmware.hook                    \
    "

DEBIAN_DEPENDS = " \
    ifupdown, isc-dhcp-client, net-tools, iputils-ping, ssh, sshd-regen-keys, bluez"

do_install() {
    install -v -d ${D}/etc/wireless-regdb/pubkeys
    #
    # install TI WL183x Wireless firmware R8.8
    # get from https://git.ti.com/cgit/wilink8-wlan/build-utilites/
    #
    install -v -d ${D}/lib/firmware
    install -v -m 644 ${WORKDIR}/firmware/regulatory.db     ${D}/lib/firmware/
    install -v -m 644 ${WORKDIR}/firmware/regulatory.db.p7s ${D}/lib/firmware/
    install -v -d ${D}/lib/firmware/ti-connectivity
    install -v -m 644 ${WORKDIR}/firmware/ti-connectivity/wl18xx-fw-4.bin       ${D}/lib/firmware/ti-connectivity/
    install -v -m 644 ${WORKDIR}/firmware/ti-connectivity/wl1271-nvs.bin        ${D}/lib/firmware/ti-connectivity/
    install -v -m 644 ${WORKDIR}/firmware/ti-connectivity/wl18xx-conf.bin       ${D}/lib/firmware/ti-connectivity/
    #
    # install TI BT service packs v4.5
    # download from https://git.ti.com/cgit/ti-bt/service-packs/
    #
    install -v -m 644 ${WORKDIR}/firmware/ti-connectivity/TIInit_11.8.32.bts    ${D}/lib/firmware/ti-connectivity/

    # install wireless & bluetooth service
    install -v -d ${D}/usr/bin
    install -v -d ${D}/lib/systemd/system/
    install -v -m 644 ${WORKDIR}/srg52c-wl18xx-wlan0        ${D}/usr/bin/
    install -v -m 644 ${WORKDIR}/srg52c-wlan0.service       ${D}/lib/systemd/system/
    install -v -m 644 ${WORKDIR}/srg52c-bt-en               ${D}/usr/bin/
    install -v -m 644 ${WORKDIR}/srg52c-bluetooth.service   ${D}/lib/systemd/system/

    install -v -d ${D}/etc/modprobe.d
    install -v -m 644 ${WORKDIR}/btwilink-blacklist.conf ${D}/etc/modprobe.d/

    # add hooks for initramfs
    HOOKS=${D}/etc/initramfs-tools/hooks
    install -m 0755 -d ${HOOKS}
    # install -m 0740 ${WORKDIR}/wl18xx-bts-firmware.hook ${HOOKS}/wl18xx-bts-firmware.hook
    install -m 0740 ${WORKDIR}/wl18xx-wlan-firmware.hook ${HOOKS}/wl18xx-wlan-firmware.hook
}

addtask do_install after do_transform_template
