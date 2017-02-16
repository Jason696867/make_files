# Redstripe Cross Environment Setup

The following steps are required to work with a console:

1. Configure the VirtualBox VM

2. Configure project tools in Ubuntu

3. Prepare a bootable SD card and/or USB stick

4. Configure the console

5. Enable booting from NAND

These are one-time activities, until there are changes to
the development toolchain,
the root filesystem of the console,
or the bootable SD card.
See the last section "Updates" in this document to update
an already installed cross-development environment.

After that you can power and use the console with the root filesystem
hosted by your Ubuntu VM, or with the rootfs on the SD card, or with
the rootfs in a NAND partition.


## Configure the VirtualBox VM

The following steps will need to be performed on the Restripe VM’s
configuration settings from Virtualbox as well as the guest VM itself.

1. First, make sure that the guest VM has been shut down.

2. Next, from Virtualbox pull-down menu option and in the ‘Settings’ we need
   to make changes to the ‘Network’ for the Restripe guest VM.

3. For tab labled ‘Adapter 1’ select for ‘Attached to’ field ‘Bridged Adapter’.
   For the ‘Name’ field select a real NIC device other than the NIC connected to RJ54
   interface. On my Medtronic laptop I use the wifi nic called ‘Intel® Centrino® Advanced-N 6205’.
   But YMMV based on the nic(s) you have on the PC. This will most likely be your corporate
   internet access to the VM.

4. Next navigate to the tab labled ‘Adapter 2’ and select ‘Attached to’ field ‘
   Bridged Adapter’. For the ‘Name’ field select the NIC device that is attached to RJ45
   interface. On my Medtronic laptop I use ‘Intel® 82579LM Gigabit Network Connection’.
   Again YMMV. This will be the closed circuit network between the VM host and RFS200
   target used for NFS mounting.


## Configure Ubuntu

There are two make targets to configure Ubuntu for redstripe project activity.

The first target installs and configures the required applications and tools
for NFS mounting and serial connections to the console.

        make cross-console

The second target also installs the cross-development toolchain.
To configure Ubuntu for cross development run

        make cross-develop

Note: the top-level Makefile will invoke recursive make here if the toolchain
or rootfs are needed (to respectively compile and deploy the target apps).


## Prepare a boot device

To create a bootable device insert a 4GB or larger SD Card or USB stick
into the computer
(you may need to pass it to the VM from the VirtualBox Devices menu).

Run --as root-- the interactive script to deploy the system to your card:

        sudo ./prepare_redstripe_device

You will be asked to select the device to build, and the console type (E, LDV, or X)
with which the boot device will be used. This takes about three minutes once you've
answered the initial questions.

Be careful with this command, since it will attempt to partition and format
whatever device you specify.


## Configure the Console

1. Connect the Ethernet cable between the console and the USB-Ethernet adapter plugged
   into the computer, which is specified as 'Adaptor 2' in the VM Configuration.

2. The two pins next to the comm port need to be connected, by e.g. jumper.
   Connect the jumper stud to the 'boot' pins on the digital board next to the UART header pins.
   This forces the system to load u-boot from the SD Card.

3. Insert the SD Card into the socket on the digital board.
   The digital board is the bottom board.
   You'll want to use thin fingers or remove the top boards for access.

3. Connect the FTDI UART cable to the console and the computer.
   This is the comm port, i.e. plug into the comm port pins on the bottom board.
   The arrow on the connector goes in the pin next to the jumped pins.

4. Capture the FTDI USB device in the VM via the VirtualBox Devices-&gt;USB menu.


### Power the Console

1. Power on the console.

2. By default the console will launch the redstripe application.

3. To observe the boot sequence, one can optionally start minicom in Ubuntu with
   the following command: `sudo minicom redstripe`
   A short while after power-on, the minicom terminal will ask for a login.

4. If you're a developer, you can ssh as root and login with password 'root'.


## Enable booting from NAND

In order to boot from NAND, after the procedure described above is done,
see crossdevelop/to-nand/README.md


## Cross-Development Work

The top-level Makefile is set to use the toolchain when you compile
the apps and tests for the target, e.g.

        make target-apps

The correct version of qmake is invoked, which leads to using the required
paths and setting for our target architecture.

You should not need to make any changes to the source code or Qt Creator environment.


## Updates

If you have already performed the above steps and simply want to update the
cross-development environment:

1. Update the uImage on the SD card, if needs be. You can either remove
   the SD card from the console and mount it on your computer, to then
   deploy files as described in the above section "Prepare a boot device";
   or use the NFS-mounted rootfs to copy the latest uImage and install it
   via a shell session on the console:

        cp crossdevelop/images/uImage rootfs-assets/root/uImage-new
        make deploy-target-apps

        (power on the console)
        (ssh to the console)
        sdcard=/mnt/sdcard
        mkdir -p $sdcard
        mount /dev/mmcblk0p2 $sdcard
        cp uImage-new $sdcard/boot/uImage
        umount $sdcard
        rmdir $sdcard
        (power off the console)

2. Update the toolchain and rootfs:

        make -C crossdevelop update-toolchain
        make -C crossdevelop update-rootfs
