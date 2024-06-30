#!/usr/bin/env bash
#https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.html#usrlibexec
#https://groups.google.com/g/comp.unix.shell/c/2Wvk1O8ReG0
#pyenv.git grep -Po -ihR  '\${bash_source[^}]+}' . | sort -u
#echo ${BASH_SOURCE} ${BASH_SOURCE[*]} ${BASH_SOURCE[@]} ${#BASH_SOURCE[@]} 
#The command `readlink -e' is equivalent to `realpath -e'. 

#https://unix.stackexchange.com/questions/68484/what-does-1-mean-in-a-shell-script-and-how-does-it-differ-from
#I summarized Stéphane Chazelas' answer:

#    ${1:+"$@"}' test if $1 null or unset
#    ${1+"$@"}' test if $1 unset

#man bash
#  Parameter Expansion
#       When  not  performing  substring expansion, using the forms documented below (e.g., :-), bash
#       tests for a parameter that is unset or null.  Omitting the colon results in a test only for a
#       parameter that is unset.

#       ${parameter:-word}
#              Use  Default  Values.  If parameter is unset or null, the expansion of word is substi‐
#              tuted.  Otherwise, the value of parameter is substituted.
#      ${parameter:+word}
#              Use Alternate Value.  If parameter is null or unset, nothing is substituted, otherwise
#              the expansion of word is substituted.

#echo $# ${1:-${BASH_SOURCE[0]}}
#return 0 2>/dev/null || exit 0

#https://groups.google.com/g/comp.unix.shell/c/tof4eopmdU8
#Pure bash shell implementation for: $(basename "${1:-${BASH_SOURCE[0]}}")
unset scriptdir_realpath
unset script_realdirname script_dirname
unset script_realname script_name
unset script_realpath script_path
unset pkg_realpath
unset script_realbasename script_basename
unset script_realextname script_extname


#Dirname: invalid option – ‘b’
#https://discourse.gnome.org/t/dirname-invalid-option-b/13851/4
#“MOTD” is short for “message of the day”, and is the traditional method for displaying a message to users on login.

#But now that I glanced at the screenshot a second time, the error warning appears after the “Last login” message. That means it’s not the motd, but from some login scripts (like /etc/profile, ~/.bash_profile)

scriptdir_realpath=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

script_realdirname=$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")
script_dirname=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

script_realname=$(basename "$(realpath -e "${BASH_SOURCE[0]}")")
script_name=$(basename "${BASH_SOURCE[0]}")

#https://groups.google.com/g/comp.unix.shell/c/tof4eopmdU8/m/_p9kLoBgCwAJ
#Unfortunately, the #, ##, %% and % operators can't be used with
#general expressions.  They only can be applied to variable names. 
#But you can achieve the wanted result in two steps: 

#script_name="${BASH_SOURCE[0]}" && script_name="${script_name2##*/}" 

script_realpath=$script_realdirname/$script_realname
script_path=$script_dirname/$script_name

pkg_realpath=${script_realpath%.*}

script_realbasename=${script_realname%.*}
script_basename=${script_name%.*}

script_realextname=${script_realname##*.}
script_extname=${script_name##*.}

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

#      https://discourse.gnome.org/t/are-you-sure-you-want-to-proceed-message-on-login/13758/7?u=hongyi-zhao
#      That means that there is a erroneous git diff command in /etc/profile or (more likely) one the files sourced by it. Start at /etc/profile and check for git diff and if that does not contain it, check all the files sourced by it (and the files sourced by those, etc.). Those are lines either starting with a . or with source. It’s probably going to be in something like ~/.profile or ~/.bashrc. Once you found the git diff line, try commenting it out.

#      if ! git -C / diff --quiet; then 
#        git -C / diff | sudo tee /$(git -C $ROOTSHARE_REPO rev-parse HEAD).diff > /dev/null
#        sudo git -C / reset --hard
#      fi

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


  # 获取第一个目录的 inode 和 device 号
  stat1=$(stat -c '%D %i' "$(realpath -e $HOME/.git 2>/dev/null)")

  # 获取第二个目录的 inode 和 device 号
  stat2=$(stat -c '%D %i' "$(realpath -e $HOMESHARE_REPO_GIT_DIR)")

  # 比较 inode 和 device 号
  if [[ "$stat1" == "$stat2" ]]; then
    # "两个目录是同一个目录"
    return
  else
    rm -fr $HOME/.git
    ln -snf $HOMESHARE_REPO_GIT_DIR $HOME/
    git -C $HOME reset --hard
  fi

  # 此部分代码已经处理了 ~/.profile.d/900-homeshare.git.bash 中的下面代码的工作：
  #if ! git -C $HOME diff --quiet; then
  #  git -C $HOME diff > $HOME/$(git -C $HOMESHARE_REPO rev-parse HEAD).diff
  #  git -C $HOME reset --hard
  #fi

  #if [[ -d $HOMESHARE_REPO_GIT_DIR ]]; then
  #  if ! git --work-tree=$HOME --git-dir=$HOMESHARE_REPO_GIT_DIR diff --quiet; then 
  #    git --work-tree=$HOME --git-dir=$HOMESHARE_REPO_GIT_DIR diff > $HOME/$(git -C $HOMESHARE_REPO rev-parse HEAD).diff
  #    git --work-tree=$HOME --git-dir=$HOMESHARE_REPO_GIT_DIR reset --hard
  #  fi      
  #fi
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









