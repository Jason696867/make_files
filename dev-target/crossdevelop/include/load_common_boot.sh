#!/bin/bash

if [[ -z "${target_device}" ]]; then
    echo "Device not selected"
    exit 1
fi
if [[ -z "${filesystem_mount_point}" ]]; then
    echo "Mount point not defined"
    exit 1
fi

echo "Load ${filesystem_mount_point} base file system"

tar xjf images/rfs200-rootfs.tar.bz2 -C "/media/${filesystem_mount_point}"

mkdir -p "/media/${filesystem_mount_point}/boot"
cp images/uImage "/media/${filesystem_mount_point}/boot"
sync

echo "Copying /opt/redstripe..."
# A fresh build and deployment of the target apps under the NFS-mounting
# rootfs is necessary for /opt/redstripe. It will be copied later from
# this device during the NAND deployment.
# @todo: build & deploy a fresh copy for the device being prepared. 
opt="/media/${filesystem_mount_point}/opt"
mkdir -p "$opt"
cp -r "/opt/rfs200-rootfs/opt/redstripe" "$opt/"

# Populates the overlay components for this device, but disables launch of
# the redstripe apps as this device is exclusively intended for installation
# of the NAND.
echo "Populating overlay in rootfs..."
rsync --recursive --checksum --perms --quiet \
	--exclude=/etc/init.d/ \
	"../rootfs-assets/" "/media/${filesystem_mount_point}/"

sync; sync; sync
