#!/bin/bash

if [[ -z "${target_device}" ]]; then
    echo "SD Card not selected"
    exit 1
fi


echo "Load RFS_BOOT partition for use in ${sd_uenv}"
for f in images/uImage images/sdcard/*; do
	cp "$f" /media/RFS_BOOT/
done

cp "images/sdcard/uEnv.txt.${sd_uenv}" /media/RFS_BOOT/uEnv.txt

sync; sync; sync
