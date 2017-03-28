#!/usr/bin/env sh

if [ $# -eq 0 ]; then
    echo "Please specify container name."
    exit 1
fi

containerName="${1}"
target="/var/lib/machines/${containerName}"

if [ -d "${target}" ]; then
    echo "${target} already exists. Aborting.."
    exit 1
fi

echo -e -n "\033[32mCreate the target directory, ${target}? (y|n) \033[0m"
read -r proceed
case $proceed in
    "y")
        sudo mkdir ${target}
        break;;
    *)
        echo -e "Aborted."
        exit 1
        break;;
esac


echo -e -n "\033[32mInstall archlinux to ${target}? (y|n) \033[0m"
read -r proceed
case $proceed in
    "y")
        sudo pacstrap -i -c -d ${target} base --ignore=linux
        break;;
    *)
        echo -e "Aborted."
        exit 1
        break;;
esac

echo -e "\033[32mContainer created. Now run the following commands.\033[0m"
echo -e "\033[32m\tsudo systemd-nspawn --boot --directory=${target}\033[0m"
echo -e "\033[32m\tLog in as root (no password).\033[0m"
echo -e "\033[32m\t(from container) passwd\033[0m"
echo -e "\033[32m\t(from container) mkdir /home/${USER}\033[0m"
echo -e "\033[32m\t(from container) useradd ${USER}\033[0m"
echo -e "\033[32m\t(from container) passwd ${USER}\033[0m"
echo -e "\033[32m\t(from container) pacman -S [packages]\033[0m"

echo -e "\033[32mThen enable the container on boot (optional).\033[0m"
echo -e "\033[32m\tsudo systemctl enable machines.target\033[0m"
echo -e "\033[32m\tsudo systemctl enable systemd-nspawn@${target}.service\033[0m"
echo -e "\033[32m\tsudo systemctl edit --full systemd-nspawn@${target}.service\033[0m"

echo -e "\033[32mAlternatively, start the container.\033[0m"
echo -e "\033[32m\tsudo systemd-nspawn --boot --tmpfs=/home/${USER}:mode=777 --bind=/tmp/.X11-unix --bind=/dev/snd --directory=${target}\033[0m"

echo -e "\033[32mYou can start a sandboxed program like below.\033[0m"
echo -e "\033[32m\tsudo systemd-run --machine=${containerName} --uid=${USER} --setenv=DISPLAY=:0.0 /usr/bin/firefox\033[0m"

echo -e "\033[32mDon't forget to run xhost +local: too!\033[0m"


# sudo systemd-nspawn --boot --directory=/var/lib/machines/chromium --bind=/tmp/.X11-unix --bind=/dev/snd --bind=/run/user/1000/pulse:/run/user/host/pulse --tmpfs=/home/takao:mode=777 --setenv=PULSE_SERVER=/run/user/host/pulse/native --network-veth
