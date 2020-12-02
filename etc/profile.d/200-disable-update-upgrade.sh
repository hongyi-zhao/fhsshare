#!/usr/bin/env bash

if dpkg -l unattended-upgrades | grep -q '^ii '; then
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


#https://askubuntu.com/questions/291063/how-to-disable-update-notification-for-all-users
#In newer versions of Ubuntu, there is a (hidden) per-user config option for this.

#Just run (as the user for whom you want to disable notifications):

#gsettings set com.ubuntu.update-notifier no-show-notifications true

#Or, if you prefer doing things visually, run dconf-editor, browse to /com/ubuntu/update-notifier and enable the no-show-notifications option.


#$ sudo apt install dconf-editor
#$ gsettings list-recursively | grep -i no-show-notifications
#$ gsettings list-recursively com.ubuntu.update-notifier
if [[ $( gsettings get com.ubuntu.update-notifier no-show-notifications ) = false ]]; then
  gsettings set com.ubuntu.update-notifier no-show-notifications true
fi

#https://askubuntu.com/questions/446395/how-to-turn-off-software-updater-xubuntu
if dpkg -l crudini | grep -q '^ii '; then
  sudo apt-get install -y crudini
fi

if [[ $(crudini --get /etc/xdg/autostart/update-notifier.desktop 'Desktop Entry' Hidden 2>/dev/null) != "true" ]]; then
  sudo crudini --set /etc/xdg/autostart/update-notifier.desktop 'Desktop Entry' Hidden true
fi


#https://developer.gnome.org/gio/stable/gsettings-tool.html
#https://itectec.com/ubuntu/ubuntu-where-can-i-get-a-list-of-schema-path-key-to-use-with-gsettings/
##!/bin/bash
## Gnome 3 can be customised from the command line via the gsettings command
## This script should help you to find what you're looking for by
## listing the ranges for all keys for each schema

#for schema in $(gsettings list-schemas | sort)
#do
#    for key in $(gsettings list-keys $schema | sort)
#    do
#        value="$(gsettings range $schema $key | tr "\n" " ")"
#        echo "$schema :: $key :: $value"
#    done
#done


