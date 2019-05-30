#!/bin/sh
# install.sh will call this seperate script to further configure the system

# adjusting timezone
ln -sf /usr/share/zoneinfo/"$1" /etc/localtime
hwclock --systohc

# configuring locales
sed -i "s/^#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen && locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# creating hostname and hosts files
echo "$2" > /etc/hostname
tee /etc/hosts <<EOF > /dev/null
127.0.0.1   localhost
::1         localhost
127.0.1.1   $2.localdomain $2
EOF

echo "root:$3" | chpasswd

grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/efi --bootloader-id=GRUB
grub-mkconfig --output=/efi/grub/grub.cfg
