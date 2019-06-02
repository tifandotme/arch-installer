#!/bin/sh
# Arch Linux installation script

# curl https://tinyurl.com/rifqid > in
# bash in

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
root="5"
swap="1"

# specify whether or not you are running on a virtual machine to determine the video drivers that is going to be installed
isVM="true"

mirrorlist() {
	echo "Fetching mirrorlist"

	curl -Os https://raw.githubusercontent.com/ifananvity/arch-installer/master/lib/rankmirrors.sh

	# fetch and ranks a live mirrorlist
	curl -s "https://www.archlinux.org/mirrorlist/?country=$country&protocol=https&protocol=http&ip_version=4" | \
	sed -e "s/^#Server/Server/g; /^#/d" | \
	bash rankmirrors.sh -n 6 - > /etc/pacman.d/mirrorlist
}

partition() {
	echo "Partitioning"

	if [ -d /sys/firmware/efi/efivars ]; then
		# create a GPT partitions for UEFI system
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
	else
		# create a MBR partitions for BIOS system
		root=$((root * 1024 + 1))
		swap=$((swap * 1024 + root))
		parted -s /dev/sda mklabel msdos \
			mkpart primary ext4 1MiB "$root"MiB \
			mkpart primary linux-swap "$root"MiB "$swap"MiB \
			mkpart primary ext4 "$swap"MiB 100% \
			set 1 boot on

		# formatting
		mkfs.ext4 -F /dev/sda1 > /dev/null 2>&1
		mkfs.ext4 -F /dev/sda3 > /dev/null 2>&1

		# mounting
		mount /dev/sda1 /mnt > /dev/null 2>&1
		mkdir /mnt/home
		mount /dev/sda3 /mnt/home > /dev/null 2>&1

		# initialize swap partition
		mkswap /dev/sda2 > /dev/null 2>&1
		swapon /dev/sda2 > /dev/null 2>&1
	fi
}

install() {
	echo "Installing packages"

	# base packages
	packages="base base-devel intel-ucode linux-headers networkmanager openssh dosfstools mtools os-prober xorg-server xorg-xinit xdg-user-dirs grub"
	[ -d /sys/firmware/efi/efivars ] && packages="${packages} efibootmgr"

	# video drivers for either VM or intel intergrated graphics
	if ( $isVM ); then
		packages="${packages} xf86-video-vmware virtualbox-guest-modules-arch virtualbox-guest-utils"
	else
		packages="${packages} xf86-video-intel"
	fi

	# general packages
	packages="${packages} openbox obmenu obconf tint2 nitrogen rxvt-unicode \
		git htop"

	# packages to consider
	# libglvnd(included in mesa), mesa(included in xorg-server), network-manager-applet wireless_tools wpa_supplicant dialog

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

	curl -s https://raw.githubusercontent.com/ifananvity/arch-installer/testing/config.sh -o /mnt/config.sh
	chmod +x /mnt/config.sh
	arch-chroot /mnt ./config.sh "$timezone" "$hostname" "$rootPassword" "$username" "$userPassword"
	rm -f /mnt/config.sh
}

# MAIN

mirrorlist
partition
install
configure
