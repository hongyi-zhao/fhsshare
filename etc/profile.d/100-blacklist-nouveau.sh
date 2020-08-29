#!/usr/bin/env bash

#https://linuxconfig.org/how-to-disable-blacklist-nouveau-nvidia-driver-on-ubuntu-20-04-focal-fossa-linux
#$ sudo bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
#$ sudo bash -c "echo options nouveau modeset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf"

# For installation of the nvidia official driver, need to disable Nouveau nvidia driver first.

# If nvidia driver is installed correctly, the following command should be executed successfully.
# So we can use it to judge whether or not we should disable Nouveau nvidia driver.
# nvidia-smi -L | grep -q '^GPU '

#https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#runfile-nouveau-ubuntu

#    Create a file at /etc/modprobe.d/blacklist-nouveau.conf with the following contents:

#    blacklist nouveau
#    options nouveau modeset=0

#    Regenerate the kernel initramfs:

#    $ sudo update-initramfs -u



blacklist_nvidia_nouveau_conf=/etc/modprobe.d/blacklist-nouveau.conf
if type -afp nvidia-smi >/dev/null; then
  if ! grep -q '^blacklist nouveau' $blacklist_nvidia_nouveau_conf 2>/dev/null; then
    # https://stackoverflow.com/questions/8467424/echo-newline-in-bash-prints-literal-n
    #sudo bash -c "echo -e 'blacklist nouveau\noptions nouveau modeset=0' > $blacklist_nvidia_nouveau_conf"
    #sudo bash -c "echo $'blacklist nouveau\noptions nouveau modeset=0' > $blacklist_nvidia_nouveau_conf"
    #sudo bash -c "echo blacklist nouveau$'\n'options nouveau modeset=0 > $blacklist_nvidia_nouveau_conf"
    sudo bash -c "printf 'blacklist nouveau\noptions nouveau modeset=0\n' > $blacklist_nvidia_nouveau_conf"
  fi
fi


