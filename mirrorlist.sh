#!/bin/sh
# Arch Linux installation script
#

curl -s "https://archlinux.org/mirrorlist/?country=ID&protocol=https&ip_version=4&use_mirror_status=on" | \
sed -n "s/#Server/Server/pg; /Generated/p"