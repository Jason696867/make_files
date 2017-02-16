#!/bin/bash

if [[ -z "${target_device}" ]]; then
    echo "SD Card not selected"
    exit 1
fi

target_device_mounts=$(cut --delimiter=" " --fields=1 /proc/mounts |grep "${target_device}")
for mount_point in ${target_device_mounts}; do
    umount ${mount_point}
done
echo ${target_device}

dd if=/dev/zero of=${target_device} bs=1024 count=1024

size=$(fdisk -l ${target_device} |grep Disk |grep bytes |awk '{print $5}')

if [[ -z "$size" ]]; then
	echo "fdisk cannot read size of ${target_device}"
	exit 1
fi

echo "DISK SIZE - $size bytes"

cylinders=$(echo $size/255/63/512 |bc)

echo "CYLINDERS - $cylinders"

{
echo ,9,0x0C,*
echo ,,,-
} | sfdisk --quiet -D -H 255 -S 63 -C $cylinders ${target_device}

sleep 3
