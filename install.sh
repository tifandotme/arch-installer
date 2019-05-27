#!/bin/sh
# Arch Linux minimal installation script for UEFI motherboard

# parameters
password="123"

echo "root:$password" | chpasswd
systemctl enable --now sshd

timedatectl set-ntp true
timedatectl set-timezone Asia/Jakarta

curl -s "https://www.archlinux.org/mirrorlist/?country=SG&protocol=https&ip_version=4" | \
sed -e "s/^#Server/Server/g; /^#/d" | \
bash rankmirrors.sh -n 6 - > /etc/pacman.d/mirrorlist
