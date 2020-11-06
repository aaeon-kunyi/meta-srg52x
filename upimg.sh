#!/bin/sh

if [ -b $1 ]; then
sudo umount $1
sudo dd if=build/tmp/deploy/images/srg-3352c/srg52-image-srg52-buster-srg-3352c.wic.img of=$1 bs=4M status=progress conv=fsync && sync
#tar xzOf build/tmp/deploy/images/srg-3352c/srg52-image-srg52-buster-srg-3352c.tar.gz | sudo dd of=$1 bs=4M status=progress conv=fsync && sync
echo "force write back"
sudo dd if=$1 of=/dev/null count=2000000 status=progress
fi

