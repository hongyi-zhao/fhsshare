#!/usr/bin/env bash
# Obtain the canonicalized absolute dirname where the script resides.
# Both readlink and realpath can do the trick.

# In the following method, the $script_realdirname is equivalent to $topdir_realpath:
script_realpath="$(realpath -e -- "${BASH_SOURCE[0]}")"
topdir_realpath=$(
cd -P -- "$(dirname -- "$script_realpath")" &&
pwd -P
) 

if [[ "$script_realpath" =~ ^(.*)/(.*)$ ]]; then
  script_realdirname="${BASH_REMATCH[1]}"
  script_realname="${BASH_REMATCH[2]}"
  #echo script_realdirname="$script_realdirname"
  #echo script_realname="$script_realname"
  # . not appeared in script_realname at all.
  if [[ "$script_realname"  =~ ^([^.]*)$ ]]; then
    script_realbasename="$script_realname"
    #echo script_realbasename="$script_realbasename"
  else
    # . appeared in script_realname. 
    # As far as filename is concerned, when . is used as the last character, it doesn't have any spefical meaning.
    # Including . as the beginning character.
    if [[ "$script_realname"  =~ ^([.].*)$ ]]; then
      script_realextname="$script_realname"
      #echo script_realextname="$script_realextname"
      # Including . but not as the beginning/trailing character.
    elif [[ "$script_realname"  =~ ^([^.].*)[.]([^.]+)$ ]]; then
      script_realbasename="${BASH_REMATCH[1]}"
      script_realextname="${BASH_REMATCH[2]}"
      #echo script_realbasename="$script_realbasename"
      #echo script_realextname="$script_realextname"
    fi
  fi
fi


script_path="${BASH_SOURCE[0]}"
topdir_path=$(
cd -P -- "$(dirname -- "$script_path")" &&
pwd -P
) 

if [[ "$scriptpath" =~ ^(.*)/(.*)$ ]]; then
  scriptdirname="${BASH_REMATCH[1]}"
  scriptname="${BASH_REMATCH[2]}"
  #echo scriptdirname="$scriptdirname"
  #echo scriptname="$scriptname"
  # . not appeared in scriptname at all.
  if [[ "$scriptname"  =~ ^([^.]*)$ ]]; then
    scriptbasename="$scriptname"
    #echo scriptbasename="$scriptbasename"
  else
    # . appeared in scriptname. 
    # As far as filename is concerned, when . is used as the last character, it doesn't have any spefical meaning.
    # Including . as the beginning character.
    if [[ "$scriptname"  =~ ^([.].*)$ ]]; then
      scriptextname="$scriptname"
      #echo scriptextname="$scriptextname"
      # Including . but not as the beginning/trailing character.
    elif [[ "$scriptname"  =~ ^([^.].*)[.]([^.]+)$ ]]; then
      scriptbasename="${BASH_REMATCH[1]}"
      scriptextname="${BASH_REMATCH[2]}"
      #echo scriptbasename="$scriptbasename"
      #echo scriptextname="$scriptextname"
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
# Only triggering the cd operation when the following conditions meet:
# The $script_realbasename isn't a command name; 
# The script isn't being sourced.
git_repo=$topdir_realpath/$script_realbasename
if ! type -at $script_realbasename >/dev/null && ! type -at $script_basename >/dev/null && [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ $git_repo =~ [^/]+[.]git$ ]]; then
    ncore=$(sudo dmidecode -t 4 | grep 'Core Enabled:' | awk '{a+=$NF}END{ print a }') 
    if [ ! -d $git_repo ]; then
      remote_origin_url_https=$(sed -re "s|^$HOME/Public/repo/|https://|" <<< $git_repo)
      remote_origin_url_git=$(sed -re "s|^$HOME/Public/repo/|git://|" <<< $git_repo)
      if [ "$(curl -o /dev/null -x socks5://127.0.0.1:18888 -I -L -s -w '%{http_code}' $remote_origin_url_https)" -eq 200 ]; then
        git clone $remote_origin_url_https $git_repo 
      else
        git clone $remote_origin_url_git $git_repo 
      fi
    fi
    cd $git_repo
  else
    if [ -d "$git_repo" ]; then 
      cd $git_repo
    else
      cd $topdir_realpath  
    fi
  fi
fi

# Execute the judgemant logic for using the self-defined git function when the corresponding git repo exists.
if ! type -at $script_basename >/dev/null && [[ "$(declare -pF git 2>/dev/null)" =~ ' -fx ' ]] && [[ "${BASH_SOURCE[0]}" = "${0}" ]] && [ -d "$git_repo/.git" ]; then
  prepare_repo () {
    sudo git clean -xdf
    git reset --hard
    git pull
  }
fi 
  
build_dep () {
  pkgname=$(tr [A-Z] [a-z] <<< "${script_realbasename%.git}")
  if apt-cache pkgnames | egrep -q "^${pkgname}$"; then
    sudo apt-get build-dep -y $pkgname
  fi
}
  
#if declare -F prepare_repo >/dev/null; then
#or
if type -t prepare_repo >/dev/null; then
  prepare_repo
fi

non_zero_status () {
  status_code=$?
  echo '*** Ouch! Exiting ***'
  echo "The script_realpath: ${script_realpath}"
  exit $status_code
}

#$script_realdirname is equivalent to $topdir_realpath.
#$script_dirname is equivalent to $topdir_path.


# The idea

# Use a separate local disk/partition/remote filesystem, say, nfs, as the $ROOTSHARE partition,
# to populate the corresponding stuff which its directories conform to the
# Filesystem Hierarchy Standard，FHS:
# https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard

# Based on the xdg base directory specifications, find out which directories can be completely/partially shared.
# For the former, put it into the public $HOMESHARE/ directory, for the latter, only put the corresponding partially shared
# subdirectories into the corresponding location in the $HOMESHARE/ directory.

# For the corresponding (system|user)-wide settings, restore them by git repos as following:
# system-wide:
# https://github.com/hongyi-zhao/rootshare.git
# user-wide:
# https://github.com/hongyi-zhao/homeshare.git


# Finally, use the xdg autostart script and shell profile to automate the settings.



# these scripts are sourced by lexical / dictionary order,
# when there are two or more scripts to be sourced, make sure use correct filenames to
# ensure the execute logic among these scripts.


#For Apollo D-kit hardware platform.
#$ sudo dmidecode -s baseboard-manufacturer | egrep --color 'Neousys Technology Inc\.'
#Neousys Technology Inc.

# This directory holds the share data for all users under / hierarchy:
ROOTSHARE=/rootshare
# This directory holds the share data for all non-root users under $HOME hierarchy:
HOMESHARE=$ROOTSHARE/homeshare

ROOTSHARE_REPO=$HOMESHARE/Public/repo/github.com/hongyi-zhao/rootshare.git
ROOTSHARE_REPO_GIT_DIR=$ROOTSHARE_REPO/.git

HOMESHARE_REPO=$HOMESHARE/Public/repo/github.com/hongyi-zhao/homeshare.git
HOMESHARE_REPO_GIT_DIR=$HOMESHARE_REPO/.git  

    
# Don't use `findmnt -r`, this use the following rule which makes the regex match impossiable for
# specifial characters, say space.
#       -r, --raw
#              Use  raw  output  format.   All  potentially  unsafe  characters  are  hex-escaped
#              (\x<code>).

# Don't run this script repeatedly:
if findmnt -l -o TARGET | grep -qE "^$ROOTSHARE$"; then
  return
fi

# Only do the settings for non-root users:
if [ "$( id -u )" -ne 0 ]; then
  if [ ! -d $ROOTSHARE ]; then
    sudo mkdir -p $ROOTSHARE
    #sudo chown -hR root:root $ROOTSHARE
  fi

  # https://unix.stackexchange.com/questions/68694/when-is-double-quoting-necessary
  # https://stackoverflow.com/questions/10067266/when-to-wrap-quotes-around-a-shell-variable

  while IFS= read -r uuid; do
    if ! findmnt -l -o TARGET | grep -qE "^$ROOTSHARE$"; then
      sudo mount -U $uuid $ROOTSHARE
    fi
  
    if [[ -d "$ROOTSHARE_REPO" && -d "$HOMESHARE_REPO" ]]; then
      # Third party applications, say, intel's tools, are intalled under this directory:
      OPTSHARE=$ROOTSHARE/opt
      if [ ! -d $OPTSHARE ]; then
        sudo mkdir $OPTSHARE
      fi

      if ! findmnt -l -o TARGET | grep -qE "^/opt$"; then
        sudo mount -o rw,rbind $OPTSHARE /opt
      fi

      if [[ "$(realpath -e /.git 2>/dev/null)" != "$(realpath -e $ROOTSHARE_REPO_GIT_DIR)" ]]; then
        sudo rm -fr /.git
        sudo ln -sfr $ROOTSHARE_REPO_GIT_DIR /
        sudo git -C / reset --hard
      fi

      if ! git -C / diff --quiet; then 
        git -C / diff | sudo tee /$(git -C $ROOTSHARE_REPO rev-parse HEAD).diff > /dev/null
        sudo git -C / reset --hard
      fi

      break
    else
      sudo umount $ROOTSHARE
    fi
  done < <( lsblk -n -o type,uuid,mountpoint | awk 'NF >= 2 && $1 ~ /^part$/ && $2 ~/[0-9a-f-]{36}/ && $NF != "/" { print $2 }' )


  # For debug the errors occurred in the variables assignment operation.
  #echo user_id="$( id -u )" 
  #echo ROOTSHARE_REPO="$ROOTSHARE_REPO"
  #echo HOMESHARE_REPO="$HOMESHARE_REPO"


  #https://specifications.freedesktop.org/menu-spec/latest/
  #https://wiki.archlinux.org/index.php/XDG_Base_Directory
  # XDG_DATA_DIRS
  # List of directories seperated by : (analogous to PATH).
  # Should default to /usr/local/share:/usr/share.

  #for desktop files search:

  # ref: ubuntu:
  # /etc/profile.d/xdg_dirs_desktop_session.sh
  if ! grep -Eq "$HOME/[.]local/share[/]?(:|$)" <<< $XDG_DATA_DIRS; then
    export XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS
  fi

  #if ! grep -Eq '/usr/local/share[/]?(:|$)' <<< $XDG_DATA_DIRS; then
  #  export XDG_DATA_DIRS=/usr/local/share:$XDG_DATA_DIRS
  #fi

  #if ! grep -Eq '/usr/share[/]?(:|$)' <<< $XDG_DATA_DIRS; then
  #  export XDG_DATA_DIRS=/usr/share:$XDG_DATA_DIRS
  #fi

  # attach the stuff found on $HOMESHARE/ at $HOME/:

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

  # Attach all top-level subdirectories found on $HOMESHARE/ at $HOME/:
  #$ find /rootshare/homeshare -maxdepth 1 -mindepth 1 -type d -printf "\"%P\"\n" | sed -re 's|$| \\|' 
  #"Pictures" \
  #"Templates" \
  #"News" \
  #"Videos" \
  #"Music" \
  #"docker" \
  #"Downloads" \
  #".profile.d" \
  #"Documents" \
  #".emacs.d" \
  #".gnus.d" \
  #".vim" \
  #"VirtualBox VMs" \
  #".pan2" \
  #".ssh" \
  #".cache" \
  #"Desktop" \
  #".aiida" \
  #"Mail" \
  #"snap" \
  #"delegate" \
  #".gnupg" \
  #"go" \
  #"Public" \
  #".brew" \
  #".conda" \
  #".wine" \
  #".pki" \

  
  #find -L $HOMESHARE/ -mindepth 1 -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.][^/]*$" -printf '%P\n' |
  find $HOMESHARE/ -mindepth 1 -maxdepth 1 -type d -printf '%f\n' |
  while IFS= read -r line; do
    if [ ! -d "$HOME/$line" ]; then
      mkdir "$HOME/$line"
    fi

    if ! findmnt -l -o TARGET | grep -qE "^$HOME/$line$"; then
      sudo mount -o rw,rbind "$HOMESHARE/$line" "$HOME/$line"
    fi
  done

  if [[ -d $HOMESHARE_REPO_GIT_DIR ]]; then
    if ! git --work-tree=$HOME --git-dir=$HOMESHARE_REPO_GIT_DIR diff --quiet; then 
      git --work-tree=$HOME --git-dir=$HOMESHARE_REPO_GIT_DIR diff > $HOME/$(git -C $HOMESHARE_REPO rev-parse HEAD).diff
      git --work-tree=$HOME --git-dir=$HOMESHARE_REPO_GIT_DIR reset --hard
    fi      
  fi   
fi






#https://bytefreaks.net/gnulinux/bash/how-to-execute-find-that-ignores-git-directories
#Example 1: Ignore all .git folders no matter where they are in the search path

#For find to ignore all .git folders, even if they appear on the first level of directories or any in-between until the last one, add -not -path '*/\.git*' to your command as in the example below.
#This parameter will instruct find to filter out any file that has anywhere in its path the folder .git. This is very helpful in case a project has dependencies in other projects (repositories) that are part of the internal structure.
#1
#
#find . -type f -not -path '*/\.git/*';

#Note, if you are using svn use:
#1
#
#find . -type f -not -path '*/\.svn/*';
#Example 2: Ignore all hidden files and folders

#To ignore all hidden files and folders from your find results add -not -path '*/\.*' to your command.
#1
#
#find . -not -path '*/\.*';

#This parameter instructs find to ignore any file that has anywhere in its path the string /. which is any hidden file or folder in the search path!


#http://mywiki.wooledge.org/UsingFind
#-path looks at the entire pathname, which includes the filename (in other words, what you see in find's output of -print) in order to match things.
#(At this point, I must point out that -path is not available on every version of find. In particular, Solaris lacks it. But it's pretty common on everything else.)




  # Some other tests which also can to the job:
  #find -L $PWD/.*  -maxdepth 0 -type d ! -path '*/.local' -regextype posix-extended -regex ".*/[.][^.][^/]*$"
  #find -L $PWD/ -mindepth 1 -maxdepth 1 -type d ! -path '*/.local' -path "$PWD/.*"
  #find -L $PWD/ -mindepth 1 -maxdepth 1 -type d ! -path '*/.local' -regextype posix-extended -regex ".*/[.][^/]*$"
  #find -L $PWD/ $PWD/.local $PWD/.local/share -mindepth 1  -maxdepth 1 -type d ! -path '*/.local' ! -path '*/.local/share' -path "$PWD/.*"

  #https://askubuntu.com/questions/76808/how-do-i-use-variables-in-a-sed-command


  # Dealing with hidden directories via one find command:
  #find -L $HOMESHARE/ $HOMESHARE/.local $HOMESHARE/.local/share \
  #     -mindepth 1  -maxdepth 1 -type d ! -path "$HOMESHARE/.local" ! -path "$HOMESHARE/.local/share" -path "$HOMESHARE/.*" 2>/dev/null |
  #sed -E "s|^$HOMESHARE/||" |
  #while IFS= read -r line; do
  #  if [ ! -d $HOME/"$line" ]; then
  #    mkdir -p $HOME/"$line"
  #  fi

  #  if ! findmnt -l -o TARGET | grep -qE "^$HOME/$line$"; then
  #    sudo mount -o rw,rbind $HOMESHARE/"$line" $HOME/"$line"
  #  fi
  #done
  
  
  
# ref：
# https://unix.stackexchange.com/questions/348321/purpose-of-the-autostart-scripts-directory
#https://specifications.freedesktop.org/autostart-spec/autostart-spec-latest.html
#https://wiki.archlinux.org/index.php/XDG_Base_Directory
#https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html

#     XDG_CONFIG_HOME
#
#         Where user-specific configurations should be written (analogous to /etc).
#
#         Should default to $HOME/.config.
#
#
#
#     XDG_CACHE_HOME
#
#         Where user-specific non-essential (cached) data should be written (analogous to /var/cache).
#
#         Should default to $HOME/.cache.
#
#
#
#     XDG_DATA_HOME
#
#         Where user-specific data files should be written (analogous to /usr/share).
#
#         Should default to $HOME/.local/share.









