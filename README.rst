meta-srg52x
===========

the repository for produce latest Debian buster OS image for `AAEON SRG-3352x Gateway <https://www.aaeon.com/en/p/iot-gateway-node-systems-srg-3352c>`_.

The build system used for this is `Isar <https://github.com/ilbers/isar>`_, an image generator that assembles Debian binaries or builds individual packages from scratch.

Development Host
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

6. Flash OS image into EMMC
   
   A. follow step 5. to make a bootable SD card
   B. insert the SD card to want flash device
   C. power on the device and login default account ::

      user:aaeon

      password:aaeon

   D. run the below command for flash OS image into EMMC until the system tune off ::

    sudo /opt/scripts/tools/srg3352c_emmc_flasher.sh
    
   E. remove the SD card, reset or run power cycle to check boot from EMMC

Known issues:
-------------
for developer:
    currently sometime will got build failed result when re-gerneration image, like the below message
    ::

     E: Sub-process /usr/bin/dpkg returned an error code (1)
     WARNING: exit code 100 from a shell command.
     ERROR: Logfile of failure stored in: /work/build/tmp/work/srg52-buster-armhf/srg52-image-srg-3352c-wic-targz-img/1.0-beta-r01-r0/temp/log.do_rootfs_install.777
     ERROR: Task (/repo/recipes-core/images/srg52-image.bb:do_rootfs_install) failed with exit code '1'
     NOTE: Tasks Summary: Attempted 153 tasks of which 140 didn't need to be rerun and 1 failed.
     Summary: 1 task failed:
     /repo/recipes-core/images/srg52-image.bb:do_rootfs_install
     Summary: There was 1 ERROR message shown, returning a non-zero exit code.
     2020-11-26 05:38:10 - ERROR    - Command returned non-zero exit status 1

    workaround method: to clean srg52-image, run the below commands
    ::

     ./shell_srg52.sh             # for entry shell of builder docker
     bitbake -c clean srg52-image # run clean srg52-image
     exit                         # quit the shell
     ./build_srg52.sh             # now for re-gerneration image


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
