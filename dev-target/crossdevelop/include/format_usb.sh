#!/bin/bash

if [[ -z "${target_device}" = ]]; then
    echo "USB Drive not selected"
    exit 1
fi

dev=$(echo "${target_device}" |cut -d"/" -f3)
target_partition_found=$(grep ${dev}1 /proc/partitions)
if [[ -z "${target_partition_found}" ]]; then
    echo "First partition not found on ${target_device}"
    exit 1
fi


echo "Formatting USB_ROOT partition"
mkfs.ext3 -L USB_ROOT ${target_device}1
