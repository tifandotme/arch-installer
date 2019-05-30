#!/bin/sh
# Arch Linux installation script for UEFI systems

# PARAMETERS
hostname="eddies"
timezone="Asia/Jakarta"
password="1"    # root password
country="SG"    # country where we will be fetching our mirrorlist from
root="5"        # partition size in GiB
swap="1"        # partition size in GiB, the remainder will be assigned to /home

mirrorlist() {
    echo "Fetching mirrorlist"

    pacman -Syy --noconfirm pacman-contrib > /dev/null 2>&1

    # fetching and ranking a live mirrorlist
    curl -s "https://www.archlinux.org/mirrorlist/?country=$country&protocol=https&ip_version=4" | \
    sed -e "s/^#Server/Server/g; /^#/d" | \
    rankmirrors -n 6 - > /etc/pacman.d/mirrorlist
}

partition() {
    echo "Partitioning"

    # creating GPT partitions
    root=$((root * 1024 + 261))
    swap=$((swap * 1024 + root))
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
    mkdir /mnt/efi /mnt/home
    mount /dev/sda1 /mnt/efi > /dev/null 2>&1
    mount /dev/sda4 /mnt/home > /dev/null 2>&1

    # initializing swap partition
    mkswap /dev/sda3 > /dev/null 2>&1
    swapon /dev/sda3 > /dev/null 2>&1
}

install() {
    echo "Installing packages"

    pacstrap /mnt base base-devel grub efibootmgr > /dev/null 2>&1

    genfstab -U /mnt >> /mnt/etc/fstab
}

configure() {
    echo "Configuring"
    
    curl -s https://raw.githubusercontent.com/ifananvity/arch-installer/master/config.sh -o /mnt/config.sh
    chmod +x /mnt/config.sh
    arch-chroot /mnt ./config.sh "$timezone" "$hostname" "$password"
    rm -f /mnt/config.sh
}

# MAIN

mirrorlist
partition
install
configure
