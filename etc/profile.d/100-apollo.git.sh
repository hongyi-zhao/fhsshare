#!/usr/bin/env bash
# Obtain the canonicalized absolute dirname where the script resides.
# Both readlink and realpath can do the trick.

# In the following method, the $script_dirname is equivalent to $topdir:
script_realpath="$(realpath -e -- "${BASH_SOURCE[0]}")"

topdir=$(
cd -P -- "$(dirname -- "$script_realpath")" &&
pwd -P
) 

if [[ "$script_realpath" =~ ^(.*)/(.*)$ ]]; then
  script_dirname="${BASH_REMATCH[1]}"
  script_name="${BASH_REMATCH[2]}"
  #echo script_dirname="$script_dirname"
  #echo script_name="$script_name"
  # . not appeared in script_name at all.
  if [[ "$script_name"  =~ ^([^.]*)$ ]]; then
    script_basename="$script_name"
    #echo script_basename="$script_basename"
  else
    # . appeared in script_name. 
    # As far as filename is concerned, when . is used as the last character, it doesn't have any spefical meaning.
    # Including . as the beginning character.
    if [[ "$script_name"  =~ ^([.].*)$ ]]; then
      script_extname="$script_name"
      #echo script_extname="$script_extname"
      # Including . but not as the beginning/trailing character.
    elif [[ "$script_name"  =~ ^([^.].*)[.]([^.]+)$ ]]; then
      script_basename="${BASH_REMATCH[1]}"
      script_extname="${BASH_REMATCH[2]}"
      #echo script_basename="$script_basename"
      #echo script_extname="$script_extname"
    fi
  fi
fi

#https://unix.stackexchange.com/questions/18886/why-is-while-ifs-read-used-so-often-instead-of-ifs-while-read

# software/anti-gfw/not-used/vpngate-relative/ecmp-vpngate/script/ovpn-traverse.sh
# man find:
# -printf format
# %f     File's name with any leading directories removed (only the last element).
# %h     Leading directories of file's name (all but the last element).  
# If the file name contains  no  slashes
#             (since it is in the current directory) the %h specifier expands to `.'.       
# %H     Starting-point under which file was found.  
# %p     File's name.
# %P     File's name with the name of the starting-point under which it was found removed.

#https://superuser.com/questions/731425/bash-detect-execute-vs-source-in-a-script
#https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
# Only triggering the cd command logic when script is not being sourced.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [ -d "$topdir/$script_basename" ]; then 
    cd $topdir/$script_basename
    if [[ $script_basename =~ [.]git$ ]]; then
      ncore=$(sudo dmidecode -t 4 | grep 'Core Enabled:' | awk '{a+=$NF}END{ print a }')
    fi
  else
    cd $topdir  
  fi
fi


#https://github.com/ApolloAuto/apollo/blob/master/docs/specs/D-kit/Waypoint_Following/Apollo_Installation_cn.md#%E8%AE%BE%E7%BD%AEapollo%E7%BC%96%E8%AF%91%E7%8E%AF%E5%A2%83

#https://github.com/ApolloAuto/apollo/issues/12293#issuecomment-683233953
#export APOLLO_ROOT_DIR=$topdir/$script_basename

#https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
#https://groups.google.com/forum/#!topic/comp.unix.shell/DD04hWElRy8
#https://stackoverflow.com/questions/48957195/how-to-fix-docker-got-permission-denied-issue
if test -S /var/run/docker.sock; then
  if ! groups $USER | grep -q docker; then
    sudo groupadd docker
    newgrp docker
    sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
    sudo chmod g+rwx "$HOME/.docker" -R
    sudo gpasswd -a $USER docker  
    sudo usermod -aG docker $USER 
  fi
  
  #https://github.com/ApolloAuto/apollo/issues/12509#issuecomment-691742501
  #https://github.com/ApolloAuto/apollo/issues/12257#issuecomment-682305336

  #if [[ $(stat -c '%a' /var/run/docker.sock) != 777 ]]; then
  #  sudo chmod 777 /var/run/docker.sock
  #fi
fi



