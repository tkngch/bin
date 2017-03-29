#!/usr/bin/sh

# pacman -Ss otf | /usr/bin/awk '{print $1}' > /tmp/f
pacman -Ss otf || ttf | /usr/bin/awk '{print $1}' > /tmp/f
awk 'NR%2 != 0' /tmp/f > /tmp/fonts
pacman -S `cat /tmp/fonts`
rm -f /tmp/f /tmp/fonts
