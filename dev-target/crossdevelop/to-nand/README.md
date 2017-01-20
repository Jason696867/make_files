# Transition from SD card to NAND

This document provides a procedure to transition the Console
from development environment based (MMC and NFS) booting
to a deployment based (entirely from NAND) booting.

The second part describes how to switch between development and deployment modes,
important for automated testing and engineering support using the flexible
development mode or switching to this mode when needed.


## Set Up NAND Based Booting

In order to transition RFS200 Console to boot from NAND based images
in a standalone manner (from development mode to deployment mode),
make sure that it is first setup to boot via MMC/NFS (development mode).
See crossdevelop/README.md

Follow this step-by-step procedure to enable boot from NAND:

1. Program the spl image from SD card's boot partition to the NAND partition.
   To boot via SD/MMC into u-boot prompt:
   start your minicom terminal on the host;
   power on the Console (note: with SD card in place);
   and halt (halt auto-boot) the u-boot loader by quickly pressing the 'ENTER' key.

   At the u-boot prompt (U-boot#), enter the following command:

        run installspl

   Turn console power off.

2. Erase and program all blocks on the required NAND partitions.
   Boot the console via SD/MMC.

   If the rootfs is NFS-mounted (i.e. you are not booting from the recommended
   standalone SD card), make the `to-nand` directory available to the console
   by running these three commands on the host:

        sudo rsync --recursive --checksum --perms --delete crossdevelop/to-nand /opt/rfs200-rootfs/opt
        sudo cp crossdevelop/images/uImage crossdevelop/images/nand/* /opt/rfs200-rootfs/opt/to-nand/
        sudo cp -r rootfs-assets "/opt/rfs200-rootfs/opt/to-nand/overlay"

   *end of commands specific to NFS-mounted rootfs*

   Log into the console root shell (via minicom or ssh) and perform the following steps:

        cd  /opt/to-nand
        ./prepare_redstripe_nand

   The NAND is set to the same console type (E, LDV, or X) as recorded under /opt/redstripe
   on the SD card (or in the NFS-mounted system).

   This takes approximately 2 minutes to complete.

   Turn console power off.

3. Remove the SD card, boot with NAND!  The active RFS partition is determined
   by the u-boot environment variable `rfs_partition`.

   The permanent data partition is mounted under `/opt/redstripe/data`

   The available bank for a new RFS as part of a software update is
   mounted under `/mnt/newrfs`

   The above two NAND partitions will not be mounted when booting from a
   standalone SD card nor with SD card + NFS-mounted rootfs.

4. If you are done upgrading consoles with NFS-mounted rootfs, you may want
   to remove the NAND-preparation images from the NFS-mounted directory
   on the host:

        sudo rm -rf /opt/rfs200-rootfs/opt/to-nand
