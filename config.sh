#!/bin/sh
# install.sh will call this seperate script to further configure the system

# adjust timezone
ln -sf /usr/share/zoneinfo/"$1" /etc/localtime
hwclock --systohc

# configure locales
sed -i "s/^#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen && locale-gen > /dev/null
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# create hostname and hosts file
echo "$2" > /etc/hostname
tee /etc/hosts <<EOF > /dev/null
127.0.0.1   localhost
::1         localhost
127.0.1.1   $2.localdomain $2
EOF

if [ -d /sys/firmware/efi/efivars ]; then
    grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/efi --bootloader-id=GRUB > /dev/null 2>&1
    grub-mkconfig --output=/efi/grub/grub.cfg > /dev/null 2>&1
else
    grub-install --target=i386-pc /dev/sda > /dev/null 2>&1
    grub-mkconfig --output=/boot/grub/grub.cfg > /dev/null 2>&1
fi

# create a new user and allow sudo
useradd -m -g users -G wheel -s /bin/bash "$4"
echo "$4:$5" | chpasswd
echo "root:$3" | chpasswd
sed -i "s/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g" /etc/sudoers

cp /etc/X11/xinit/xinitrc ~/.xinitrc

curl -Os https://raw.githubusercontent.com/ifananvity/dotfiles/master/.bashrc \
         https://raw.githubusercontent.com/ifananvity/dotfiles/master/.xinitrc

systemctl enable NetworkManager sshd > /dev/null 2>&1

sed -i "s/^#Color/Color/; /#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
