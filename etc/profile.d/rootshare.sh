#!/usr/bin/env bash 

# ref：
# From: Alan Mackenzie <acm@muc.de>
# Newsgroups: comp.unix.shell
# Subject: How do I convert a filename to absolute in bash?
# 改为下面的实现：

# 进一步发现了下面的方法：
# 得到shell脚本文件所在完整路径（绝对路径）及文件名（无论source,bash,.三种调用方式），
# 且不改变shell的当前目录。

# ref：
# https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself
# 上文中谈到：
# if you call it from a "source ../../yourScript", $0 would be "bash"!
# 
# 故基于 $0 实现的方法，对于 使用 source 命令的时候会失效。
# ref：
# From: Hongyi Zhao <hongyi.zhao@gmail.com>
# Newsgroups: comp.unix.shell
# Subject: Cann't obtain the script's directory from within sript itself by
#  uisng the . command.

# 参考下面的出错信息：
# werner@debian-01:~$ realpath -e -- bash
# realpath: bash: No such file or directory

# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within

# 发现脚本所在的实际物理路径的目录名：

topdir=$(
cd -P -- "$(dirname -- "$(realpath -e -- "${BASH_SOURCE[0]}")" )" &&
pwd -P
) 

# echo $topdir

# or
# 
# topdir=$(
# cd -P -- "$(dirname -- "$(readlink -e -- "${BASH_SOURCE[0]}")" )" &&
# pwd -P
# )  

# echo $topdir

# cd $topdir/doh-dot-dnscrypt



# 当脚本是一个链接时，下面的操作发现的是该链接所在的目录：
# topdir=$(
# cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
# pwd -P
# )

# echo $topdir




# The idea 

# Use a seperated local partition/remote filesystem ( say, nfs ), for my case, $ROOTSHARE,
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

# 一些用到的变量：
# system_uuid
#system_uuid="$( sudo dmidecode -s system-uuid )"
# root uuid
#root_uuid="$( findmnt -alo TARGET,SOURCE,UUID -M /  | tail -1 | awk ' { print $NF } ' )"
# current user
_user="$( ps -o user= -p $$ | awk '{print $1}' )"

# default home of the current user

# Use the $HOME will do the job, so just keep it simple and stupid.

#getent passwd "$_user" | cut -d: -f6
#_HOME=$( awk -v FS=':' -v user=$_user '$1 == user { print $6}' /etc/passwd ) 

# If not exist
if [ ! -d "$HOME" ]; then
  sudo mkdir $HOME
fi

# fix the owner, group and mode bits
if [ "$( stat -c "%U %G %a" $HOME )" != "$_user $_user 755" ]; then
  sudo chown -hR $_user:$_user $HOME
  sudo chmod -R 755 $HOME 
fi


# Discarded the $NEW_HOME based method, so the following desription is not applied now:

# According to the current logic, the $HOME directory 
# is used as the mountpoint for $NEW_HOME.  Consider the following case: 
# when login the system then logout, and re-login,
# for this case, the $HOME will have all the stuff mounted there.

# If we do the operation ` rm -fr $HOME ', 
# all of the stuff mounted there will be deleted, dangerous! 

# In order to prepare a clean $HOME, we must first ensure that we don't delete any user's stuff
# mounted at $HOME, so this thing is done by the following conditions:

# $HOME not empty
# $HOME not be used as a mountpoint

# Though this is safe, but it seems that this is not a good idea.
# In the early stage of the login process, many processes may need this directory to be there.

# On the other hand, the /etc/xdg/autostart/xdg-virtualroot.{desktop,sh} scripts 
# will only can be run when user doing a the desktop login.
# In this case, the $HOME is still needed to exist at the corresponding location.

# So, the most feasiable method should be keep $HOME as it is.  And only mount the stuff on 
# $NEW_HOME and $HOMESHARE at $HOME using the specific mounting order described following. 

#From: Helmut Waitzmann <nn.throttle@xoxy.net>
#Newsgroups: comp.unix.shell
#Subject: Re: The portable way to judge a empty directory.
#… or just a '-prune', which is POSIX compliant, while '-maxdepth' 
#is not.

#if [ -z "$( sudo find "$HOME" -maxdepth 0 -type d -empty )" ] &&           
#   ! findmnt -al | grep -qE "^$HOME[ ]+"; then 
#  sudo rm -fr $HOME
#  sudo mkdir $HOME
#fi


# Due to discard the $NEW_HOME based method, there is no need to export the following now:
# export virtualroot relative vars:
ROOTSHARE=/rootshare

if [ ! -d "$ROOTSHARE" ]; then
  sudo mkdir -p $ROOTSHARE
  #sudo chown -hR root:root $ROOTSHARE
fi

# https://unix.stackexchange.com/questions/68694/when-is-double-quoting-necessary
# https://stackoverflow.com/questions/10067266/when-to-wrap-quotes-around-a-shell-variable
while IFS= read -r uuid; do
  if ! findmnt -al | grep -qE "^$ROOTSHARE[ ]+"; then 
    sudo mount -U $uuid $ROOTSHARE
  fi   
       
  if [ -d "$ROOTSHARE/rootshare.git" ]; then
    ROOTSHARE_GIT=$ROOTSHARE/rootshare.git 
    #HOMESHARE_GIT=$ROOTSHARE/homeshare.git
 
    # This directory is for holding public data:
    HOMESHARE=$ROOTSHARE/home/share

    # Third party applications, say, intel's tools, are intalled in this directory for sharing:
    OPTSHARE=$ROOTSHARE/opt
       
 
    if [ ! -d "$OPTSHARE" ]; then
      sudo mkdir $OPTSHARE
    fi

    if ! findmnt -al | grep -qE "^/opt[[:blank:]]"; then
      sudo mount -o rw,rbind $OPTSHARE /opt
    fi

    # *** important note: ***
    # Once you mount disk on a folder, everything inside the original folder gets temporarily
    # hidden and replaced by content of the mounted disk. 
    
    # mount the git repo should be done after all other mount operations.
    # this can prevent the config files comes from the git repo
    # be hiddened by other mount operations using the same file tree path. 
    if [ ! -d "/.git" ]; then
      sudo mkdir /.git
    fi

    if ! findmnt -al | grep -qE "^/.git[[:blank:]]"; then
      sudo mount -o rw,rbind $ROOTSHARE_GIT/.git /.git
      # https://remarkablemark.org/blog/2017/10/12/check-git-dirty/
      for dir in $ROOTSHARE_GIT /; do  
        #if ! sudo git --work-tree=$dir --git-dir=$dir/.git diff --quiet; then
        if ! sudo git -C $dir diff --quiet; then
          #sudo git --work-tree=$dir --git-dir=$dir/.git reset --recurse-submodules --hard
          # it's not need to use --recurse-submodules for this case.    
          sudo git -C $dir reset --hard
        fi
      done       
    fi
    break
  else
    sudo umount $ROOTSHARE
  fi
done < <( lsblk -o uuid,fstype,mountpoint | awk -v mountpoint=$ROOTSHARE ' $2 == "ext4" && ( $3 == "" || $3 == mountpoint ) { print $1 } ' )


# Use the following conditions now:
if [ "$( id -u )" -ne 0 ] && [ -d "$ROOTSHARE_GIT" ] && [ -d "$HOMESHARE" ]; then 



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

  if ! grep -Eq '/usr/local/share[/]?(:|$)' <<< $XDG_DATA_DIRS; then
    export XDG_DATA_DIRS=/usr/local/share:$XDG_DATA_DIRS 
  fi

  if ! grep -Eq '/usr/share[/]?(:|$)' <<< $XDG_DATA_DIRS; then
    export XDG_DATA_DIRS=/usr/share:$XDG_DATA_DIRS
  fi

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
	
  # non-hidden directories:
  find -L "$HOMESHARE"/ -mindepth 1 -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.].*" -printf '%P\n' |
  while IFS= read -r line; do
    if [ ! -d $HOME/"$line" ]; then
      mkdir $HOME/"$line"
    fi

    if ! findmnt -al | grep -qE "^$HOME/$line[[:blank:]]"; then
      sudo mount -o rw,rbind $HOMESHARE/"$line" $HOME/"$line"
    fi
  done




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
  #find -L $PWD/.*  -maxdepth 0 -type d ! -path '*/.local' -regextype posix-extended -regex ".*/[.][^.].*$" 
  #find -L $PWD/ -mindepth 1 -maxdepth 1 -type d ! -path '*/.local' -path "$PWD/.*" 
  #find -L $PWD/ -mindepth 1 -maxdepth 1 -type d ! -path '*/.local' -regextype posix-extended -regex ".*/[.].*" 
  #find -L $PWD/ $PWD/.local $PWD/.local/share -mindepth 1  -maxdepth 1 -type d ! -path '*/.local' ! -path '*/.local/share' -path "$PWD/.*" 

  #https://askubuntu.com/questions/76808/how-do-i-use-variables-in-a-sed-command

  
  # Dealing with hidden directories via one find command:
  find -L $HOMESHARE/ $HOMESHARE/.local $HOMESHARE/.local/share \
       -mindepth 1  -maxdepth 1 -type d ! -path '*/.local' ! -path '*/.local/share' -path "$HOMESHARE/.*" |
  sed -E "s|^$HOMESHARE/||" |
  while IFS= read -r line; do
    if [ ! -d $HOME/"$line" ]; then
      mkdir -p $HOME/"$line"
    fi

    if ! findmnt -al | grep -qE "^$HOME/$line[[:blank:]]"; then
      sudo mount -o rw,rbind $HOMESHARE/"$line" $HOME/"$line"
    fi
  done    

  # hidden directories except .local:
#  find -L "$HOMESHARE"/ -mindepth 1 -maxdepth 1 -type d ! -path '*/.local' -regextype posix-extended -regex ".*/[.].*" -printf '%P\n' |
#  while IFS= read -r line; do
#    if [ ! -d $HOME/"$line" ]; then
#      mkdir $HOME/"$line"
#    fi

#    if ! findmnt -al | grep -qE "^$HOME/$line[[:blank:]]"; then
#      sudo mount -o rw,rbind $HOMESHARE/"$line" $HOME/"$line"
#    fi
#  done

#  # .local except .local/share:
#  if [ -d "$HOMESHARE"/.local ]; then
#    find -L "$HOMESHARE"/.local/ -mindepth 1 -maxdepth 1 -type d ! -path '*/share' -regextype posix-extended -regex ".*/[^.].*" -printf '%P\n' |
#    while IFS= read -r line; do
#      if [ ! -d $HOME/.local/"$line" ]; then
#	mkdir -p $HOME/.local/"$line"
#      fi

#      if ! findmnt -al | grep -qE "^$HOME/[.]local/$line[[:blank:]]"; then
#	sudo mount -o rw,rbind $HOMESHARE/.local/"$line" $HOME/.local/"$line"
#      fi
#    done
#  fi

#  # .local/share:
#  if [ -d "$HOMESHARE"/.local/share ]; then
#    find -L "$HOMESHARE"/.local/share/ -mindepth 1 -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.].*" -printf '%P\n' |
#    while IFS= read -r line; do
#      if [ ! -d $HOME/.local/share/"$line" ]; then
#	mkdir -p $HOME/.local/share/"$line"
#      fi

#      if ! findmnt -al | grep -qE "^$HOME/[.]local/share/$line[[:blank:]]"; then
#	sudo mount -o rw,rbind $HOMESHARE/.local/share/"$line" $HOME/.local/share/"$line"
#      fi
#    done
#  fi
fi



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









