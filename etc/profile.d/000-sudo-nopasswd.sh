#!/usr/bin/env bash

sudoers_d=/etc/sudoers.d
nopasswd=$sudoers_d/nopasswd

if [ $(id -u) -ne 0 ]; then
  if [ -e $nopasswd ] && egrep -q "^$USER[[:blank:]]+ALL=\(ALL:ALL\) NOPASSWD:ALL$" $nopasswd; then
    return
  fi

  if [ ! -d "$sudoers_d" ]; then
    mkdir -p "$sudoers_d"
  fi
  
  sed -r 's/^[[:blank:]]*[|]//' <<-EOF | sudo tee $nopasswd > /dev/null  
        |$USER ALL=(ALL:ALL) NOPASSWD:ALL
	EOF
fi

