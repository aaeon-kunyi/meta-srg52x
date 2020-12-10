#!/bin/bash -e
#
# change device model to SRG-3352 from SRG-3352C
#
# Copyright (c) LYD/AAEON, 2020
#
# Authors:
#  KunYi <kunyi.chen@gmail.com>
#
# SPDX-License-Identifier: MIT
#

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

ohost=$(hostname)
if [ ! x"${ohost}" == x"SRG-3352C" ]; then
	echo "only support from SRG-3352C chage to SRG-3352"
	exit
fi

# change hostname
echo -e "127.0.1.1\tSRG-3352" >> /etc/hosts
hostnamectl set-hostname SRG-3352
sed -i 's/127\.0\.1\.1\tSRG-3352C//g' /etc/hosts

sed -i 's/SRG-3352C/SRG-3352 /g' /etc/issue
sed -i 's/SRG-3352C/SRG-3352 /g' /etc/issue.net
# setting environments
srg52cfg -f -nSRG-3352
fw_setenv board_name SRG-3352
# turn off bluetooth & wifi service
systemctl stop srg52c-bluetooth.service
systemctl stop srg52c-wlan0.service
systemctl mask srg52c-bluetooth.service
systemctl mask srg52c-wlan0.service

echo "complete setting image for SRG-3352"
