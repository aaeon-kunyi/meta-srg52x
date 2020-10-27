#
# TI U-Boot 2019.01
#
# Copyright (c) LYD/AAEON, 2020
#
# Authors:
#   KunYi <kunyi.chen@gmail.com>
#
# SPDX-License-Identifier: MIT
#
require recipes-bsp/u-boot/u-boot-custom.inc

# Build environment
PR = "r23"
BRANCH = "ti-u-boot-2019.01"
SRCREV = "a280dd38e1d3dc7f9c6ceba54fc9830fe9a152a3"

S = "${WORKDIR}/git"

U_BOOT_CONFIG ?= "am335x_evm_defconfig"
U_BOOT_BIN = "u-boot.img"

# UBOOT_LOCALVERSION can be set to add a tag to the end of the
# U-boot version string.  such as the commit id
def get_git_revision(p):
    import subprocess

    try:
        return subprocess.Popen("git rev-parse HEAD 2>/dev/null ", cwd=p, shell=True, stdout=subprocess.PIPE, universal_newlines=True).communicate()[0].rstrip()
    except OSError:
        return None

#UBOOT_LOCALVERSION = "-g${@get_git_revision('${S}').__str__()[:10]}"

UBOOT_SUFFIX ?= "img"
SPL_BINARY ?= "MLO"

FILESEXTRAPATHS_prepend := "${THISDIR}/u-boot:"

SUMMARY = "u-boot bootloader for TI devices"

LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=30503fd321432fc713238f582193b78e"

BRANCH ?= "master"
UBOOT_GIT_URI = "git://git.ti.com/ti-u-boot/ti-u-boot.git"
UBOOT_GIT_PROTOCOL = "git"
SRC_URI += "${UBOOT_GIT_URI};protocol=${UBOOT_GIT_PROTOCOL};branch=${BRANCH}"
SRC_URI += "file://0001-add-support-new-board-srg3352.patch"
SRC_URI += "file://srg-3352c-uboot-build-rules"

do_prepare_build_append() {
    # replace debian build rules
    cp ${WORKDIR}/srg-3352c-uboot-build-rules ${S}/debian/rules
    # install MLO
    echo "MLO /usr/lib/u-boot/${MACHINE}" >> \
        ${S}/debian/u-boot-${MACHINE}.install
    # install u-boot.elf
    echo "u-boot.elf /usr/lib/u-boot/${MACHINE}" >> \
        ${S}/debian/u-boot-${MACHINE}.install

    # fixed version
    echo "-SRG-3352C-2020.10" > ${B}/.scmversion
    echo "-SRG-3352C-2020.10" > ${S}/.scmversion
}
