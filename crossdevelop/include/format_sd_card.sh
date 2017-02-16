#!/bin/bash

if [[ -z "${target_device}" ]]; then
    echo "SD Card not selected"
    exit 1
fi

dev=$(echo "${target_device}" |cut -d"/" -f3)
target_partition_1_found=$(grep ${dev}1 /proc/partitions)
if [[ -z "${target_partition_1_found}" ]]; then
    echo "First partition not found"
    exit 1
fi

target_partition_2_found=$(grep ${dev}2 /proc/partitions)
if [[ -z "${target_partition_2_found}" ]]; then
    echo "Second partition not found"
    exit 1
fi


echo "Formatting RFS_BOOT partition"
mkfs.msdos -n RFS_BOOT -F 32 ${target_device}1

echo "Formatting RFS_ROOT partition"
mkfs.ext3 -L RFS_ROOT ${target_device}2
