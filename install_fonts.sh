#!/usr/bin/sh

pacman -Ss otf | egrep '^\w' | /usr/bin/awk '{print $1}' > /tmp/fonts
pacman -Ss ttf | egrep '^\w' | /usr/bin/awk '{print $1}' >> /tmp/fonts
pacman -S `cat /tmp/fonts`
# rm -f /tmp/f /tmp/fonts
