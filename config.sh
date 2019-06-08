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

# install grub and generate config file
if [ -d /sys/firmware/efi/efivars ]; then
    grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/efi --bootloader-id=GRUB > /dev/null 2>&1
    sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g" /etc/default/grub
    grub-mkconfig --output=/efi/grub/grub.cfg > /dev/null 2>&1
else
    grub-install --target=i386-pc /dev/sda > /dev/null 2>&1
    sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g" /etc/default/grub
    grub-mkconfig --output=/boot/grub/grub.cfg > /dev/null 2>&1
fi

# create a new user and allow sudo
useradd -m -g users -G wheel -s /bin/bash "$4"
echo "$4:$5" | chpasswd
echo "root:$3" | chpasswd
sed -i "s/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL= NOPASSWD: ALL, NOPASSWD: \/usr\/bin\/halt, \/usr\/bin\/poweroff, \/usr\/bin\/reboot, \/usr\/bin\/pacman -Syu, \/usr\/bin\/pacman -Syyu, \/usr\/bin\/pacman -Sy, \/usr\/bin\/pacman -Syy/g; /without a password/a Defaults \!tty_tickets" /etc/sudoers

# disable xdg-user-dirs-update on login so it doesn't overwrite user-spesific config from the dotfiles
sed -i "s/enabled=True/enabled=False/g" /etc/xdg/user-dirs.confn

# colorize output
sed -i "s/^#Color/Color/g; /#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

# configure touchpad
tee /etc/X11/xorg.conf.d/30-touchpad.conf <<EOF > /dev/null
Section "InputClass"
	Identifier "Touchpad"
	MatchIsTouchpad "on"
	Option "NaturalScrolling" "true"
	Option "ClickMethod" "clickfinger"
	Option "Tapping" "on"
EndSection
EOF

# import dotfiles
find /home/"$4"/ -mindepth 1 -delete
git clone -q https://github.com/ifananvity/dotfiles.git
mv -f dotfiles/.* -t /home/"$4"/ > /dev/null 2>&1
rm -rf dotfiles/
chown -R "$4":users /home/"$4"/

# make user directories
mkdir -p /home/$4/{Downloads,Documents,Media/Music,Media/Pictures,Media/Videos}

# start these services at startup
systemctl enable NetworkManager > /dev/null 2>&1
