meta-srg52x
===========

the repository for produce latest Debian buster OS image for `AAEON SRG-3352x Gateway <https://www.aaeon.com/en/p/iot-gateway-node-systems-srg-3352c>`_.

The build system used for this is `Isar <https://github.com/ilbers/isar>`_, an image generator that assembles Debian binaries or builds individual packages from scratch.

Developement Host
-----------------
currently use Ubuntu 18.04/20.04 -- x86_64(amd64).

1. to install the follow packages ::
    
    sudo apt update
    
    sudo apt install \
      apt-transport-https \
      ca-certificates \
      curl \
      git \
      gnupg-agent \
      software-properties-common


2. to install docker.io, please reference `this article <https://docs.docker.com/engine/install/ubuntu>`_. And to add your account into docker group and launch docker ::

    sudo usermod -aG docker <your account>
    # reminds: you can reboot the host or 
    # try the below commands for launch docker service
    sudo systemctl enable docker
    sudo systemctl start docker

3. build test image ::

    # clone this repository
    git clone https://github.com/aaeon-kunyi/meta-srg52x.git
    cd meta-srg52x
    # build image
    ./build_srg52.sh

4. image will gerneration in ./build/tmp/deploy/images/srg-3352c

    srg52-image-srg52-buster-srg-3352c.wic.img

5. Booting from SD card ::

    # Under Linux host, insert an unused SD card. Assuming the SD card takes device **/dev/sdX**, use dd to copy the image to it. For example:

    sudo dd if=./build/tmp/deploy/images/srg-3352c/srg52-image-srg52-buster-srg-3352c.wic.img of=/dev/sdX bs=4M oflag=sync

    # reminds: **/dev/sdX**, please double confirm which is your SD card.

Known issues:
-------------
* currently only support booting from SD card
* WIFI/Bluetooth maybe failed when first time boot

License:
--------
Unless otherwise stated in the respective file, files in this layer are provided under the MIT license, see COPYING file. Patches (files ending with .patch) are licensed according to their target project and file, typically GPLv2.
    
Reference:
----------
* https://github.com/siemens/kas
* https://github.com/ilbers/isar
* https://github.com/siemens/meta-iot2050
* https://gitlab.com/cip-project/cip-core/isar-cip-core
* `Bootloader base on u-boot 2019.01 from TI Linux RT SDK <https://git.ti.com/cgit/ti-u-boot/ti-u-boot/log/?h=ti-u-boot-2019.01&id=a280dd38e1d3dc7f9c6ceba54fc9830fe9a152a3>`_
* kernel base on TI Linux RT SDK with Beaglebone patch
    * `TI Processor SDK Linux RT AM335X, 06_03_00_106 <https://software-dl.ti.com/processor-sdk-linux-rt/esd/AM335X/06_03_00_106/index_FDS.html>`_
    * `Beaglebone r52 patch <https://github.com/RobertCNelson/ti-linux-kernel-dev/releases/tag/4.19.94-ti-rt-r52>`_

* https://github.com/RobertCNelson/boot-scripts
