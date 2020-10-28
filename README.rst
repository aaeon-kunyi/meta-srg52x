meta-srg52x
===========

the repository for produce latest Debian buster OS image for `AAEON SRG-3352x Gateway <https://www.aaeon.com/en/p/iot-gateway-node-systems-srg-3352c>`_.

Developement Host
-----------------
currently use Ubuntu 18.04.

1. to install the follow packages ::

    apt install \
      binfmt-support \
      build-essential \
      debootstrap \
      dosfstools \
      dpkg-dev \
      gettext-base \
      git \
      mtools \
      parted \
      python3 \
      python3-pip \
      python3-distutils \
      quilt \
      qemu \
      qemu-user-static \
      reprepro \
      sudo


2. to install docker.io, please reference `this article <https://docs.docker.com/engine/install/ubuntu>`_.

3. install kas setup tool ::

    pip3 install kas

4. build test image ::

    # clone this repository
    git clone https://github.com/aaeon-kunyi/meta-srg52x.git
    cd meta-srg52x
    # build image
    ./build_srg52.sh

5. image will gerneration in ./build/tmp/deploy/images/srg-3352c

    srg52-image-srg52-buster-srg-3352c.wic.img

6. Booting from SD card ::

    # Under Linux host, insert an unused SD card. Assuming the SD card takes device **/dev/sdX**, use dd to copy the image to it. For example:

    sudo dd if=./build/tmp/deploy/images/srg-3352c/srg52-image-srg52-buster-srg-3352c.wic.img of=/dev/sdX bs=4M oflag=sync

    # reminds: **/dev/sdX**, please double confirm which is your SD card.

Known issues:
-------------
* currently only support booting from SD card
* WIFI/Bluetooth maybe failed when first time boot
    
Reference:
----------
* https://github.com/siemens/kas
* https://github.com/ilbers/isar
* https://github.com/siemens/meta-iot2050
* https://gitlab.com/cip-project/cip-core/isar-cip-core
