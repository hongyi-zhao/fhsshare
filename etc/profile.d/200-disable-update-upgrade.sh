#!/usr/bin/env bash

if dpkg --get-selections | grep unattended-upgrades | awk '$NF == "install"'; then
  sudo apt-get remove -y unattended-upgrades
fi

#sudo systemctl disable --now apt-daily{,-upgrade}.{timer,service}
for srv in apt-daily.service \
           apt-daily.timer \
           apt-daily-upgrade.service \
           apt-daily-upgrade.timer; do
  if [[ $(systemctl is-active $srv 2>/dev/null) != inactive ]]; then
    sudo systemctl unmask $srv >/dev/null 2>&1
    sudo systemctl disable --now $srv >/dev/null 2>&1
  fi          
done
