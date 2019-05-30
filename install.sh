#!/bin/sh
# Arch Linux minimal installation script for UEFI motherboard

# password="1"
# echo "root:$password" | chpasswd
# systemctl -q start sshd

mirrorlist() {
    pacman -Syy --noconfirm pacman-contrib

    curl -s "https://www.archlinux.org/mirrorlist/?country=ID&country=SG&protocol=https&protocol=http&ip_version=4" | \
    sed -e "s/^#Server/Server/g; /^#/d" | \
    rankmirrors -n 6 - > /etc/pacman.d/mirrorlist
}

partition() {
    root=$((5 * 1024 + 261))
    swap=$((2 * 1024 + root))

    parted -s /dev/sda mklabel gpt \
        mkpart efi fat32 1MiB 261MiB \
        mkpart root ext4 261MiB "$root"MiB \
        mkpart swap linux-swap "$root"MiB "$swap"MiB \
        mkpart home ext4 "$swap"MiB 100% \
        set 1 esp on

    mkfs.fat -F32 /dev/sda1
    mkfs.ext4 -F /dev/sda2
    mkfs.ext4 -F /dev/sda4

    mkdir /mnt/{efi,home}
    mount /dev/sda1 /mnt/efi
    mount /dev/sda2 /mnt
    mount /dev/sda4 /mnt/home

    mkswap /dev/sda3
    swapon /dev/sda3
}

# MAIN

timedatectl set-ntp true
timedatectl set-timezone Asia/Jakarta

mirrorlist
partition

pacstrap /mnt base base-devel

genfstab -U /mnt >> /mnt/etc/fstab
