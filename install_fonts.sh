#!/usr/bin/sh

pacman -Ss otf | grep -E '^\w' | /usr/bin/awk '{print $1}' > /tmp/fonts
pacman -Ss ttf | grep -E '^\w' | /usr/bin/awk '{print $1}' >> /tmp/fonts
pacman -S $(cat /tmp/fonts)
# rm -f /tmp/f /tmp/fonts
