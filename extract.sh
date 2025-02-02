#!/bin/bash
# Rootfs Extractor by @Maizil41

read -p "Masukkan nama output rootfs: " ROOTFS_NAME

read -p "Masukkan tautan firmware (Wget): " FW_LINK

echo "Downloading firmware from $FW_LINK..."
wget "$FW_LINK"

FW_PATH=$(find ./ -name "*.img.*")
if [[ -z "$FW_PATH" ]]; then
    echo "Firmware path is empty. Exiting."
    exit 1
fi

echo "Extracting firmware..."
if [[ "$FW_PATH" == *.img.gz ]]; then
    sudo gunzip "$FW_PATH"
    rm -rf "$FW_PATH"
elif [[ "$FW_PATH" == *.img.xz ]]; then
    sudo unxz "$FW_PATH"
    rm -rf "$FW_PATH"
else
    echo "Unsupported file type: $FW_PATH"
    exit 1
fi

EXTRACTED_FW=$(find -name "*.img")
if [[ -z "$EXTRACTED_FW" ]]; then
    echo "No extracted firmware found. Exiting."
    exit 1
fi

fdisk_output=$(fdisk -l "$EXTRACTED_FW")
echo "$fdisk_output"
offset=$(echo "$fdisk_output" | grep "${EXTRACTED_FW}2" | awk '{print $2}')
partisi_offset=$((offset * 512))

echo "Mounting image..."
sudo mkdir -p /mnt/openwrt-rootfs
sudo mount -o loop,offset="$partisi_offset" "$EXTRACTED_FW" /mnt/openwrt-rootfs

echo "Copying root filesystem..."
mkdir -p extracted-rootfs
sudo cp -a /mnt/openwrt-rootfs/. ./extracted-rootfs/ > /dev/null 2>&1

echo "Compressing root filesystem..."
sudo tar -czvf "${ROOTFS_NAME}_rootfs.tar.gz" -C ./extracted-rootfs/ . > /dev/null 2>&1

echo "Unmounting root filesystem..."
sudo umount /mnt/openwrt-rootfs

echo "Process completed successfully."
