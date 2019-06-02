#!/bin/sh
# Arch Linux installation script for UEFI systems

# PARAMETERS
# current timezone
timezone="Asia/Jakarta"

# country where we will be fetching our live mirrorlist from
# list: https://raw.githubusercontent.com/ifananvity/arch-installer/master/lib/countries.txt
country="SG"

# computer's name
hostname="eddies"

# superuser
rootPassword="1"

# unprivileged user
username="anvity"
userPassword="2"

# root and swap partitions size in GiB, the remainder will be assigned to home partition
root="3"
swap="1"

# if running on a virtual machine, VM video driver will be installed, or else
# it will install an intel video driver
isVM="true"

mirrorlist() {
    echo "Fetching mirrorlist"

    curl -Os https://raw.githubusercontent.com/ifananvity/arch-installer/master/lib/rankmirrors.sh

    # fetch and ranks a live mirrorlist
    curl -s "https://www.archlinux.org/mirrorlist/?country=$country&protocol=https&ip_version=4" | \
    sed -e "s/^#Server/Server/g; /^#/d" | \
    bash rankmirrors.sh -n 6 - > /etc/pacman.d/mirrorlist
}

partition() {
    echo "Partitioning"

    # create GPT partitions
    root=$((root * 1024 + 261))
    swap=$((swap * 1024 + root))
    parted -s /dev/sda mklabel gpt \
        mkpart efi fat32 1MiB 261MiB \
        mkpart root ext4 261MiB "$root"MiB \
        mkpart swap linux-swap "$root"MiB "$swap"MiB \
        mkpart home ext4 "$swap"MiB 100% \
        set 1 esp on

    # formatting
    mkfs.fat -F32 /dev/sda1 > /dev/null 2>&1
    mkfs.ext4 -F /dev/sda2 > /dev/null 2>&1
    mkfs.ext4 -F /dev/sda4 > /dev/null 2>&1

    # mounting
    mount /dev/sda2 /mnt > /dev/null 2>&1
    mkdir /mnt/efi /mnt/home
    mount /dev/sda1 /mnt/efi > /dev/null 2>&1
    mount /dev/sda4 /mnt/home > /dev/null 2>&1

    # initialize swap partition
    mkswap /dev/sda3 > /dev/null 2>&1
    swapon /dev/sda3 > /dev/null 2>&1
}

install() {
    echo "Installing packages"

    # base packages
    packages="base base-devel grub efibootmgr intel-ucode linux-headers networkmanager openssh dosfstools mtools os-prober xorg-server xorg-xinit"

    if ( $isVM ); then
        # video drivers for VM
        packages="${packages} xf86-video-vmware virtualbox-guest-modules-arch virtualbox-guest-utils libglvnd mesa"
    else
        # video drivers for intel
        packages="${packages} xf86-video-intel libglvnd mesa"
    fi

    # DE/WM
    packages="${packages} openbox obmenu obconf tint2 nitrogen rxvt-unicode"

    # packages to consider
    # network-manager-applet wireless_tools wpa_supplicant dialog

    total=$(echo "$packages" | wc -w)
    for pac in $packages; do
        n=$((n+1))
        echo "  $pac ($n of $total)"

        pacstrap /mnt "$pac" > /dev/null 2>&1
    done

    genfstab -U /mnt >> /mnt/etc/fstab
}

configure() {
    echo "Configuring"

    curl -s https://raw.githubusercontent.com/ifananvity/arch-installer/master/config.sh -o /mnt/config.sh
    chmod +x /mnt/config.sh
    arch-chroot /mnt ./config.sh "$timezone" "$hostname" "$rootPassword" "$username" "$userPassword"
    rm -f /mnt/config.sh
}

# MAIN

mirrorlist
partition
install
configure
