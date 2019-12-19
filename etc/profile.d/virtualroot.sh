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

# 进一步的考虑：
# cmake：
# CMakeLIsts.txt
# make：
# Makefile

# 更简单的方法是改变脚本的命名规则，比如：

# cd $topdir/$( echo "${BASH_SOURCE[0]}" | sed -E 's/[.][^.]+$//' )



# to-do list:

#Lustre Over ZFS


# The idea 

# Use a seperated local partition/remote filesystem ( say, nfs ), for my case, the directory name is $VIRTUAL_ROOT,
# to populate the corresponding stuff which its directories conform to the   
# Filesystem Hierarchy Standard，FHS:
# https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard

# Based on the xdg base directory specifications, find out which directories can be completely/partially shared.
# For the former, put it into the public $DISTRO_DESKTOP/ directory, for the latter, only put the corresponding partially shared
# subdirectories into the corresponding location in the $DISTRO_DESKTOP/ directory.

# For the corresponding (system|user)-wide settings, restore them by git repos as following:
# system-wide:
# https://github.com/hongyi-zhao/virtualroot.git
# user-wide:
# https://github.com/hongyi-zhao/distro-desktop.git
 

# Finally, use the xdg autostart script and shell profile to automate the settings. 



# these scripts are sourced by lexical / dictionary order,
# when there are two or more scripts to be sourced, make sure use correct filenames to 
# ensure the execute logic among these scripts.

# 一些用到的变量：
# system_uuid
system_uuid="$( sudo dmidecode -s system-uuid )"
# root uuid
root_uuid="$( findmnt -alo TARGET,SOURCE,UUID -M /  | tail -1 | awk ' { print $NF } ' )"
# current user
_user="$( ps -o user= -p $$ | awk '{print $1}' )"

# _desktop 的值在某些distro 下，从 .profile 中调用，并不能返回结果。
#only run the inxi in xdg autostart scripts.
#_distro=$( inxi -c0 -Sxx | grep -Eo 'Distro: [^ ]+' | awk '{ print $2 }' )
#_desktop=$( inxi -c0 -Sxx | grep -Eo 'Desktop: [^ ]+' | awk '{ print $2 }' )

# default home of the current user
#getent passwd "$_user" | cut -d: -f6
DEFAULT_HOME=$( awk -v FS=':' -v user=$_user '$1 == user { print $6}' /etc/passwd ) 

# export virtualroot relative vars:
export VIRTUAL_ROOT=/virtualroot


# According to the current logic, the $DEFAULT_HOME directory 
# is used as the mountpoint for $NEW_HOME.  Consider the following case: 
# when login the system then logout, and re-login,
# for this case, the $DEFAULT_HOME will have all the stuff mounted there.

# If we do the operation ` rm -fr $DEFAULT_HOME ', 
# all of the stuff mounted there will be deleted, dangerous! 

 


# not exist
if [ ! -d "$DEFAULT_HOME" ]; then
  sudo mkdir $DEFAULT_HOME
fi


# In order to prepare a clean $DEFAULT_HOME, we must first ensure that we don't delete any user's stuff
# mounted at $DEFAULT_HOME, so this thing is done by the following conditions:

# $DEFAULT_HOME not empty
# $DEFAULT_HOME not be used as a mountpoint

# Though this is safe, but it seems that this is not a good idea.
# In the early stage of the login process, many processes may need this directory to be there.

# On the other hand, the /etc/xdg/autostart/xdg-virtualroot.{desktop,sh} scripts 
# will only can be run when user doing a the desktop login.
# In this case, the $DEFAULT_HOME is still needed to exist at the corresponding location.

# So, the most feasiable method should be keep $DEFAULT_HOME as it is.  And only mount the stuff on 
# $NEW_HOME and $DISTRO_DESKTOP at $DEFAULT_HOME using the specific mounting order described following. 

#From: Helmut Waitzmann <nn.throttle@xoxy.net>
#Newsgroups: comp.unix.shell
#Subject: Re: The portable way to judge a empty directory.
#… or just a '-prune', which is POSIX compliant, while '-maxdepth' 
#is not.

#if [ -z "$( sudo find "$DEFAULT_HOME" -maxdepth 0 -type d -empty )" ] &&           
#   ! findmnt -al | grep -qE "^$DEFAULT_HOME[ ]+"; then 
#  sudo rm -fr $DEFAULT_HOME
#  sudo mkdir $DEFAULT_HOME
#fi


# fix the owner, group and mode bits
if [ "$( stat -c "%U %G %a" $DEFAULT_HOME )" != "$_user $_user 755" ]; then
  sudo chown -hR $_user:$_user $DEFAULT_HOME
  sudo chmod -R 755 $DEFAULT_HOME 
fi

if [ ! -d "$VIRTUAL_ROOT" ]; then
  sudo mkdir -p $VIRTUAL_ROOT
  sudo chown -hR $_user:$_user $VIRTUAL_ROOT
fi

# https://unix.stackexchange.com/questions/68694/when-is-double-quoting-necessary
# https://stackoverflow.com/questions/10067266/when-to-wrap-quotes-around-a-shell-variable
while IFS= read -r uuid; do
  if ! findmnt -al | grep -qE "^$VIRTUAL_ROOT[ ]+"; then 
    sudo mount -U $uuid $VIRTUAL_ROOT
  fi   
       
  if [ -d "$VIRTUAL_ROOT/virtualroot.git" ]; then
    VIRTUAL_ROOT_HOME=$VIRTUAL_ROOT/home
    VIRTUAL_ROOT_INFO=$VIRTUAL_ROOT/"$system_uuid-$root_uuid-$_user"
    if [ -f "$VIRTUAL_ROOT_INFO" ]; then
      # this directory is created by /etc/xdg/autostart/xdg-virtualroot.sh
      NEW_HOME="$VIRTUAL_ROOT_HOME/$( awk '/^Distro:/{ a=$2 }/^Desktop:/{ b=$2 }END{ print a"-"b }' "$VIRTUAL_ROOT_INFO" )"
    fi
    
    # this directory is prepared for hold public data:
    DISTRO_DESKTOP=$VIRTUAL_ROOT_HOME/distro-desktop
       
    VIRTUAL_ROOT_OPT=$VIRTUAL_ROOT/opt
  
    if [ ! -d "$VIRTUAL_ROOT_OPT" ]; then
      sudo  mkdir $VIRTUAL_ROOT_OPT
      sudo  chown -hR $_user:$_user $VIRTUAL_ROOT_OPT
    fi

    if ! findmnt -al | grep -qE "^/opt[[:blank:]]"; then
      sudo mount -o rw,rbind $VIRTUAL_ROOT_OPT /opt
    fi

    # *** important note: ***
    # Once you mount disk on a folder, everything inside the original folder gets temporarily
    # hidden and replaced by content of the mounted disk. 
    
    # mount the git repo should be done after all other mount operations.
    # this can prevent the config files comes from the git repo
    # be hiddened by other mount operations using the same file tree path. 
    if [ ! -d "/.git" ]; then
      sudo  mkdir /.git
      sudo  chown -hR $_user:$_user /.git
    fi

    if ! findmnt -al | grep -qE "^/.git[[:blank:]]"; then
      sudo mount -o rw,rbind $VIRTUAL_ROOT/virtualroot.git/.git /.git
      # https://remarkablemark.org/blog/2017/10/12/check-git-dirty/
      for dir in $VIRTUAL_ROOT/virtualroot.git /; do  
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
    sudo umount $VIRTUAL_ROOT
  fi
done < <( lsblk -o uuid,fstype,mountpoint | awk -v mountpoint=$VIRTUAL_ROOT ' $2 == "ext4" && ( $3 == "" || $3 == mountpoint ) { print $1 } ' )


if [ "$( id -u )" -ne 0 ] && 
   [ -d "$NEW_HOME" ] && [[ "$DEFAULT_HOME" != "$NEW_HOME" ]] &&
   ! findmnt -al | grep -qE "^$DEFAULT_HOME[ ]+"  &&   
   [ -d "$DISTRO_DESKTOP" ]; then 


  #https://specifications.freedesktop.org/menu-spec/latest/
  #https://wiki.archlinux.org/index.php/XDG_Base_Directory
  # XDG_DATA_DIRS
  # List of directories seperated by : (analogous to PATH).
  # Should default to /usr/local/share:/usr/share.

  #for desktop files search:

  # ref: ubuntu:
  # /etc/profile.d/xdg_dirs_desktop_session.sh
  if ! grep -Eq "$DEFAULT_HOME/[.]local/share[/]?(:|$)" <<< $XDG_DATA_DIRS; then
    export XDG_DATA_DIRS=$DEFAULT_HOME/.local/share:$XDG_DATA_DIRS
  fi

  if ! grep -Eq '/usr/local/share[/]?(:|$)' <<< $XDG_DATA_DIRS; then
    export XDG_DATA_DIRS=/usr/local/share:$XDG_DATA_DIRS 
  fi

  if ! grep -Eq '/usr/share[/]?(:|$)' <<< $XDG_DATA_DIRS; then
    export XDG_DATA_DIRS=/usr/share:$XDG_DATA_DIRS
  fi



  # attach the stuff found on "$NEW_HOME" at $DEFAULT_HOME/: 
  sudo mount -o rw,rbind "$NEW_HOME" "$DEFAULT_HOME"
    

  # attach the stuff found on $DISTRO_DESKTOP/ at $DEFAULT_HOME/: 

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
  find -L "$DISTRO_DESKTOP"/ -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.][^/]*" -printf '%P\n' |
  awk 'NF > 0' |
  while IFS= read -r line; do
    if [ ! -d $DEFAULT_HOME/"$line" ]; then
      mkdir $DEFAULT_HOME/"$line"
    fi

    if ! findmnt -al | grep -qE "^$DEFAULT_HOME/$line[[:blank:]]"; then
      sudo mount -o rw,rbind $DISTRO_DESKTOP/"$line" $DEFAULT_HOME/"$line"
    fi
  done


  # hidden directories except .local:
  find -L "$DISTRO_DESKTOP"/ -maxdepth 1 -type d -regextype posix-extended -regex ".*/[.][^/]*" -printf '%P\n' |
  awk ' NF > 0 && ! /^[.]local$/ ' |
  while IFS= read -r line; do
    if [ ! -d $DEFAULT_HOME/"$line" ]; then
      mkdir $DEFAULT_HOME/"$line"
    fi

    if ! findmnt -al | grep -qE "^$DEFAULT_HOME/$line[[:blank:]]"; then
      sudo mount -o rw,rbind $DISTRO_DESKTOP/"$line" $DEFAULT_HOME/"$line"
    fi
  done

  # .local except .local/share:
  if [ -d "$DISTRO_DESKTOP"/.local ]; then
    find -L "$DISTRO_DESKTOP"/.local/ -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.][^/]*" -printf '%P\n' |
    awk 'NF > 0 && ! /^share$/ ' |
    while IFS= read -r line; do
      if [ ! -d $DEFAULT_HOME/.local/"$line" ]; then
	mkdir -p $DEFAULT_HOME/.local/"$line"
      fi

      if ! findmnt -al | grep -qE "^$DEFAULT_HOME/[.]local/$line[[:blank:]]"; then
	sudo mount -o rw,rbind $DISTRO_DESKTOP/.local/"$line" $DEFAULT_HOME/.local/"$line"
      fi
    done
  fi

  # .local/share:
  if [ -d "$DISTRO_DESKTOP"/.local/share ]; then
    find -L "$DISTRO_DESKTOP"/.local/share/ -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.][^/]*" -printf '%P\n' |
    awk 'NF > 0 ' |
    while IFS= read -r line; do
      if [ ! -d $DEFAULT_HOME/.local/share/"$line" ]; then
	mkdir -p $DEFAULT_HOME/.local/share/"$line"
      fi

      if ! findmnt -al | grep -qE "^$DEFAULT_HOME/[.]local/share/$line[[:blank:]]"; then
	sudo mount -o rw,rbind $DISTRO_DESKTOP/.local/share/"$line" $DEFAULT_HOME/.local/share/"$line"
      fi
    done
  fi


  # *** important note: *** 
  # mount the git repo should be done after all other mount operations.
  # this can prevent the config files comes from the git repo
  # be superseated by other mount operations using the same file tree path.

  # attach the stuff found on $VIRTUAL_ROOT_HOME/distro-desktop.git/.git at $DEFAULT_HOME/.git: 
  if [  -n "$VIRTUAL_ROOT_HOME" ] && [ -d $VIRTUAL_ROOT_HOME/distro-desktop.git ]; then 
    if [ "$( stat -c "%U %G %a" $VIRTUAL_ROOT_HOME/distro-desktop.git )" != "$_user $_user 755" ]; then
      sudo chown -hR $_user:$_user $VIRTUAL_ROOT_HOME/distro-desktop.git
      sudo chmod -R 755 $VIRTUAL_ROOT_HOME/distro-desktop.git
    fi
     
    if [ ! -d $DEFAULT_HOME/.git ]; then
      mkdir $DEFAULT_HOME/.git
    fi         
	
    if ! findmnt -al | grep -qE "^$DEFAULT_HOME/[.]git[[:blank:]]"; then
      sudo mount -o rw,rbind $VIRTUAL_ROOT_HOME/distro-desktop.git/.git $DEFAULT_HOME/.git
      for dir in $VIRTUAL_ROOT_HOME/distro-desktop.git $DEFAULT_HOME; do
        # it seems not need use sudo for this case:  
        #if ! git --work-tree=$dir --git-dir=$dir/.git diff --quiet; then
        if ! git -C $dir diff --quiet; then
          # git --work-tree=$dir --git-dir=$dir/.git reset --recurse-submodules --hard
          # there is no need to use --recurse-submodules for this case. 
          git -C $dir reset --hard
        fi
      done 
    fi
  fi # $VIRTUAL_ROOT_HOME/distro-desktop.git
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
#         Should default to $DEFAULT_HOME/.config.
# 
# 
# 
#     XDG_CACHE_HOME
# 
#         Where user-specific non-essential (cached) data should be written (analogous to /var/cache).
# 
#         Should default to $DEFAULT_HOME/.cache.
# 
# 
# 
#     XDG_DATA_HOME
# 
#         Where user-specific data files should be written (analogous to /usr/share).
# 
#         Should default to $DEFAULT_HOME/.local/share.









