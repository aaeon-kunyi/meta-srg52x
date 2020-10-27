#!/bin/sh
#
# SRG-335x Debian Buster
#
# Copyright (c) LYD/AAEON, 2020
#
# SRG-3352 build script
#
# Authors:
#   KunYi <kunyi.chen@gmail.com>
#
# SPDX-License-Identifier: MIT
#

kas-docker --isar build kas-srg52.yml:kas/board/srg-3352c.yml
