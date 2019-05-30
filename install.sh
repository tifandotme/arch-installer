#!/bin/sh
# Arch Linux minimal installation script for UEFI mode

# password="1"
# echo "root:$password" | chpasswd
# systemctl -q start sshd

mirrorlist() {
    echo "Configuring mirrorlist"

    pacman -Syy --noconfirm pacman-contrib > /dev/null 2>&1

    curl -s "https://www.archlinux.org/mirrorlist/?country=ID&country=SG&protocol=https&protocol=http&ip_version=4" | \
    sed -e "s/^#Server/Server/g; /^#/d" | \
    rankmirrors -n 6 - > /etc/pacman.d/mirrorlist
}

partition() {
    echo "Partitioning"

    # / and swap sizes in GiB, the rest will be assigned to /home
    root=$((5 * 1024 + 261))
    swap=$((1 * 1024 + root))

    # creating partitions
    parted -s /dev/sda mklabel gpt \
        mkpart efi fat32 1MiB 261MiB \
        mkpart root ext4 261MiB "$root"MiB \
        mkpart swap linux-swap "$root"MiB "$swap"MiB \
        mkpart home ext4 "$swap"MiB 100% \
        set 1 esp on > /dev/null 2>&1

    # formatting
    mkfs.fat -F32 /dev/sda1 > /dev/null 2>&1
    mkfs.ext4 -F /dev/sda2 > /dev/null 2>&1
    mkfs.ext4 -F /dev/sda4 > /dev/null 2>&1

    # mounting
    mount /dev/sda2 /mnt > /dev/null 2>&1
    mkdir /mnt/{efi,home} > /dev/null 2>&1
    mount /dev/sda1 /mnt/efi > /dev/null 2>&1
    mount /dev/sda4 /mnt/home > /dev/null 2>&1

    # initialize swap partition
    mkswap /dev/sda3 > /dev/null 2>&1
    swapon /dev/sda3 > /dev/null 2>&1

    # generating fstab file
    genfstab -U /mnt >> /mnt/etc/fstab
}

install() {
    echo "Installing"

    pacstrap /mnt base base-devel
}

# MAIN

timedatectl set-ntp true
timedatectl set-timezone Asia/Jakarta

mirrorlist
partition
install
