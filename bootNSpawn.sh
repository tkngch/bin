#!/usr/bin/env sh

sharedDirectory=${HOME}/tmp/nspawn/min
rm -rf ${sharedDirectory}
mkdir -p ${sharedDirectory}

echo "export DISPLAY=${DISPLAY}" >> ${sharedDirectory}/.bashrc

xhost +local:
sudo systemd-nspawn --boot --bind=/tmp/.X11-unix --bind=/dev/snd --directory=/var/lib/machines/min --bind=${sharedDirectory}:/home/takao
xhost -local:
