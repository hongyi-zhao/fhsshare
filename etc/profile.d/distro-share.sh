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




# 这些文件的执行是字典序。
# 所以要保证相应的文件名之间符合调用的先后顺序。


# 首先需要准备一个 $DISTRO_SHARE 目录， which conform to the Filesystem Hierarchy Standard，FHS:
# https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard
# 其标准是 和 https://github.com/hongyi-zhao/dotfiles.git 的内容不干扰。


if command -v inxi > /dev/null 2>&1; then 
  
# 一些用到的变量：
# system_uuid
system_uuid="$( sudo dmidecode -s system-uuid )"
# root uuid
root_uuid="$( findmnt -alo TARGET,SOURCE,UUID -M /  | tail -1 | awk ' { print $NF } ' )"
# current user
_user="$( ps -o user= -p $$ | awk '{print $1}' )"

  
# default home of the current user
#getent passwd "$_user" | cut -d: -f6
__home=$( awk -v FS=':' -v user=$_user '$1 == user { print $6}' /etc/passwd ) 

# _desktop 的值在某些distro 下，从 .profile 中调用，并不能返回结果。
_distro=$( inxi -c0 -Sxx | grep -Eo 'Distro: [^ ]+' | awk '{ print $2 }' )
_desktop=$( inxi -c0 -Sxx | grep -Eo 'Desktop: [^ ]+' | awk '{ print $2 }' )


# export distro-share relative vars:
export DISTRO_SHARE=/distro-share

# using the following code is enough:
if [ ! -d $__home ]; then
  sudo mkdir $__home
fi

if [ "$( stat -c "%U %G %a" $__home )" != "$_user $_user 755" ]; then
  sudo chown -hR $_user:$_user $__home
  sudo chmod -R 755 $__home 
fi



# https://unix.stackexchange.com/questions/68694/when-is-double-quoting-necessary
# https://stackoverflow.com/questions/10067266/when-to-wrap-quotes-around-a-shell-variable
  while IFS= read -r uuid; do
    if [ ! -d "$DISTRO_SHARE" ]; then
      sudo mkdir -p $DISTRO_SHARE
      sudo chown -hR $_user:$_user $DISTRO_SHARE
    fi
	
    if ! findmnt -al | grep -qE "^$DISTRO_SHARE[ ]+"; then 
      sudo mount -U $uuid $DISTRO_SHARE
    fi   
       
    if [ -d "$DISTRO_SHARE/distro-share.git" ]; then
      HOME_DISTRO=$DISTRO_SHARE/home
      HOME_SHARE=$HOME_DISTRO/home-share 
      OPT_SHARE=$DISTRO_SHARE/opt
      INFO_SHARE=$DISTRO_SHARE/"$system_uuid-$root_uuid-$_user"


      if [ ! -d "/.git" ]; then
        sudo  mkdir /.git
        sudo  chown -hR $_user:$_user /.git
      fi

      if ! findmnt -al | grep -qE "^/.git[[:blank:]]"; then
        sudo mount -o rw,rbind $DISTRO_SHARE/distro-share.git/.git /.git
      fi
 
       
      if [ ! -d "$OPT_SHARE" ]; then
        sudo  mkdir $OPT_SHARE
        sudo  chown -hR $_user:$_user $OPT_SHARE
      fi

      if ! findmnt -al | grep -qE "^/opt[[:blank:]]"; then
        sudo mount -o rw,rbind $OPT_SHARE /opt
      fi
      break
    else
      sudo umount $DISTRO_SHARE
    fi

  done < <( lsblk -o uuid,fstype,mountpoint | awk -v ads=$DISTRO_SHARE ' $2 == "ext4" && ( $3 == "" || $3 == ads ) { print $1 } ' )



  if [ -f "$INFO_SHARE" ]; then
    _home="$HOME_DISTRO/$( awk '/^Distro:/{ a=$2 }/^Desktop:/{ b=$2 }END{ print a"-"b }' "$INFO_SHARE" )"

    if [ x"$__home" != x"$_home" ] && [ "$( id -u )" -ne 0 ] && ! findmnt -al | grep -qE "^$HOME[ ]+"; then
      sudo mount -o rw,rbind "$_home" "$__home"

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



      if [ -d "$HOME_SHARE" ]; then

	#https://unix.stackexchange.com/questions/18886/why-is-while-ifs-read-used-so-often-instead-of-ifs-while-read

	# software/anti-gfw/not-used/vpngate-relative/ecmp-vpngate/script/ovpn-traverse.sh
	# -printf format
	# %f     File's name with any leading directories removed (only the last element).
	# %h     Leading directories of file's name (all but the last element).  
	# If the file name contains  no  slashes
	#             (since it is in the current directory) the %h specifier expands to `.'.       
	# %H     Starting-point under which file was found.  
	# %p     File's name.
	# %P     File's name with the name of the starting-point under which it was found removed.
	find -L "$HOME_SHARE"/ -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.][^/]*" -printf '%P\n' |
        awk 'NF > 0' |
	while IFS= read -r line; do
	  if [ ! -d $HOME/"$line" ]; then
	    mkdir $HOME/"$line"
	  fi

	  if ! findmnt -al | grep -qE "^$HOME/$line[[:blank:]]"; then
	    sudo mount -o rw,rbind $HOME_SHARE/"$line" $HOME/"$line"
	  fi

	done

        # dealing on "$HOME_SHARE"/home-share.git:
        if [ -d "$HOME_SHARE"/home-share.git ]; then       
  	  if [ ! -d $HOME/.git ]; then
	    mkdir $HOME/.git
	  fi         
	
          if ! findmnt -al | grep -qE "^$HOME/[.]git[[:blank:]]"; then
	    sudo mount -o rw,rbind $HOME_SHARE/home-share.git/.git $HOME/.git
	  fi
        fi


	# dealing on hidden directories except .local and home-share.git itself:
	find -L "$HOME_SHARE"/ -maxdepth 1 -type d -regextype posix-extended -regex ".*/[.][^/]*" -printf '%P\n' |
        awk ' NF > 0 && ! /^[.]local$/ &&  ! /^home-share[.]git$/ ' |
	while IFS= read -r line; do
	  if [ ! -d $HOME/"$line" ]; then
	    mkdir $HOME/"$line"
	  fi

	  if ! findmnt -al | grep -qE "^$HOME/$line[[:blank:]]"; then
	    sudo mount -o rw,rbind $HOME_SHARE/"$line" $HOME/"$line"
	  fi

	done

	# dealing on .local:
	if [ -d "$HOME_SHARE"/.local ]; then
	  find -L "$HOME_SHARE"/.local/ -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.][^/]*" -printf '%P\n' |
          awk 'NF > 0 && ! /^share$/ ' |
	  while IFS= read -r line; do
	    if [ ! -d $HOME/.local/"$line" ]; then
	      mkdir -p $HOME/.local/"$line"
	    fi

	    if ! findmnt -al | grep -qE "^$HOME/[.]local/$line[[:blank:]]"; then
	      sudo mount -o rw,rbind $HOME_SHARE/.local/"$line" $HOME/.local/"$line"
	    fi

	  done
	fi

	# dealing on .local/share:
	if [ -d "$HOME_SHARE"/.local/share ]; then
	  find -L "$HOME_SHARE"/.local/share/ -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.][^/]*" -printf '%P\n' |
          awk 'NF > 0 && ! /^share$/ ' |
	  while IFS= read -r line; do
	    if [ ! -d $HOME/.local/share/"$line" ]; then
	      mkdir -p $HOME/.local/share/"$line"
	    fi

	    if ! findmnt -al | grep -qE "^$HOME/[.]local/share/$line[[:blank:]]"; then
	      sudo mount -o rw,rbind $HOME_SHARE/.local/share/"$line" $HOME/.local/share/"$line"
	    fi

	  done
	fi
      fi
    fi
  fi
fi




# 在 .profile 中运行 inxi 能否检测到 Desktop 的值，
# 是和distro有关的。故不可靠。

# 采用这里的方法是可以的：
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









