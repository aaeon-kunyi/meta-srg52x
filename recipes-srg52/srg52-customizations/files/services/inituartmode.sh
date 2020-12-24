#!/bin/sh

set -e
if [ -f /proc/device-tree/chosen/overlays/BoardName ]; then
	boardname=$(cat /proc/device-tree/chosen/overlays/BoardName)
	echo $boardname
	if [ "x$boardname" = "xSRG-3352x Expansion Board Mode B" ]; then
		/usr/sbin/uartmode -i
		echo "complete init uartmode"
	fi
fi
