#!/bin/sh
# Arch Linux minimal installation script for UEFI motherboard

# parameters
password="123"

echo "root:$password" | chpasswd
systemctl -q enable --now sshd

timedatectl set-ntp true
timedatectl set-timezone Asia/Jakarta

pacman -Sy --noconfirm --noprogressbar pacman-contrib

curl -s "https://www.archlinux.org/mirrorlist/?country=SG&protocol=https&ip_version=4" | \
sed -e "s/^#Server/Server/g; /^#/d" | \
rankmirrors -n 6 - > /etc/pacman.d/mirrorlist
