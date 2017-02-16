#!/bin/bash

if [[ -z "${target_device}" ]]; then
    echo "USB Drive not selected"
    exit 1
fi

target_device_mounts=$(cut --delimiter=" " --fields=1 /proc/mounts |grep "${target_device}")
for mount_point in ${target_device_mounts}; do
    umount ${mount_point}
done

{
echo ",,L,*"
echo ";"
echo ";"
echo ";"
} | sfdisk $target_device

echo "Waiting for device..."
sleep 3
echo "Ready"
