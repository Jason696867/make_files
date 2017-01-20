#!/bin/bash

if [[ -z "${target_device}" ]]; then
    echo "Device not selected"
    exit 1
fi
if [[ -z "${filesystem_mount_point}" ]]; then
    echo "Mount point not defined"
    exit 1
fi

echo "Populating /opt/to-nand in ${filesystem_mount_point}..."
opt_dir="/media/${filesystem_mount_point}/opt"
cp -r to-nand "${opt_dir}/"
for f in images/uImage images/nand/*; do
	cp "$f" "${opt_dir}/to-nand/"
done

# Prepares opt/to-nand/overlay, used for the second-leg NAND deployment.
echo "- copying overlay components under /opt/to-nand..."
cp -r "../rootfs-assets" "${opt_dir}/to-nand/overlay"

sync
