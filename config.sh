#!/bin/sh
# install.sh will call this seperate script to further configure the system
# this script accept 2 parameters: timezone(1) and hostname(2)

# adjust timezone
ln -sf /usr/share/zoneinfo/"$1" /etc/localtime
hwclock --systohc

# localization
sed -i "s/^#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen && locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "$2" > /etc/hostname

tee /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $2.localdomain $2s
EOF
