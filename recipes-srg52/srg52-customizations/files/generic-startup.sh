#!/bin/sh

set -e
echo "gerneric starup"

eth0addr=$(ifconfig eth0 | grep ether | awk '{ print $2 }')
eth1addr=$(ifconfig eth1 | grep ether | awk '{ print $2 }')
testmac=$eth0addr
if [ -f /etc/srg52/eth0_mac ]; then
	unset testmac
	testmac=$(cat /etc/srg52/eth0_mac)
	if [ "x$testmac" != "x$eth0addr" ]; then
		echo "MAC of eth0 has change"
		echo "$eth0addr" > /etc/srg52/eth0_mac
	fi
else
	echo "$eth0addr" > /etc/srg52/eth0_mac
fi

