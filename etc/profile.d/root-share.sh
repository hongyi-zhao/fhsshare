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


# 首先需要准备一个 $ROOT_SHARE 目录， which conform to the Filesystem Hierarchy Standard，FHS:
# https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard
# Then combine the following two repos to do the job:
#  
# https://github.com/hongyi-zhao/root-share.git
# https://github.com/hongyi-zhao/distro-desktop.git


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

# export root-share relative vars:
export ROOT_SHARE=/root-share

if [ ! -d $DEFAULT_HOME ]; then
  sudo mkdir $DEFAULT_HOME
fi

if [ "$( stat -c "%U %G %a" $DEFAULT_HOME )" != "$_user $_user 755" ]; then
  sudo chown -hR $_user:$_user $DEFAULT_HOME
  sudo chmod -R 755 $DEFAULT_HOME 
fi

if [ ! -d "$ROOT_SHARE" ]; then
  sudo mkdir -p $ROOT_SHARE
  sudo chown -hR $_user:$_user $ROOT_SHARE
fi

# https://unix.stackexchange.com/questions/68694/when-is-double-quoting-necessary
# https://stackoverflow.com/questions/10067266/when-to-wrap-quotes-around-a-shell-variable
while IFS= read -r uuid; do
  if ! findmnt -al | grep -qE "^$ROOT_SHARE[ ]+"; then 
    sudo mount -U $uuid $ROOT_SHARE
  fi   
       
  if [ -d "$ROOT_SHARE/root-share.git" ]; then
    ROOT_SHARE_HOME=$ROOT_SHARE/home
    ROOT_SHARE_INFO=$ROOT_SHARE/"$system_uuid-$root_uuid-$_user"
    if [ -f "$ROOT_SHARE_INFO" ]; then
      NEW_HOME="$ROOT_SHARE_HOME/$( awk '/^Distro:/{ a=$2 }/^Desktop:/{ b=$2 }END{ print a"-"b }' "$ROOT_SHARE_INFO" )"
    fi

    DISTRO_DESKTOP=$ROOT_SHARE_HOME/distro-desktop

    ROOT_SHARE_OPT=$ROOT_SHARE/opt
  
    if [ ! -d "$ROOT_SHARE_OPT" ]; then
      sudo  mkdir $ROOT_SHARE_OPT
      sudo  chown -hR $_user:$_user $ROOT_SHARE_OPT
    fi

    if ! findmnt -al | grep -qE "^/opt[[:blank:]]"; then
      sudo mount -o rw,rbind $ROOT_SHARE_OPT /opt
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
      sudo mount -o rw,rbind $ROOT_SHARE/root-share.git/.git /.git
      # https://remarkablemark.org/blog/2017/10/12/check-git-dirty/
      for dir in $ROOT_SHARE/root-share.git /; do  
        if ! sudo git --work-tree=$dir --git-dir=$dir/.git diff --quiet; then
          #sudo git --work-tree=$dir --git-dir=$dir/.git reset --recurse-submodules --hard
          # it's not need to use --recurse-submodules for this case.    
          sudo git --work-tree=$dir --git-dir=$dir/.git reset --hard
        fi
      done       
    fi
    break
  else
    sudo umount $ROOT_SHARE
  fi
done < <( lsblk -o uuid,fstype,mountpoint | awk -v mountpoint=$ROOT_SHARE ' $2 == "ext4" && ( $3 == "" || $3 == mountpoint ) { print $1 } ' )


if [ "$( id -u )" -ne 0 ] && [ -n "$NEW_HOME" ] && [ "$DEFAULT_HOME" != "$NEW_HOME" ] && [ -d "$DISTRO_DESKTOP" ] &&  
   ! findmnt -al | grep -qE "^$DEFAULT_HOME[ ]+"; then

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

  # attach the stuff found on $ROOT_SHARE_HOME/distro-desktop.git/.git at $DEFAULT_HOME/.git: 
  if [  -n "$ROOT_SHARE_HOME" ] && [ -d $ROOT_SHARE_HOME/distro-desktop.git ]; then 
    if [ "$( stat -c "%U %G %a" $ROOT_SHARE_HOME/distro-desktop.git )" != "$_user $_user 755" ]; then
      sudo chown -hR $_user:$_user $ROOT_SHARE_HOME/distro-desktop.git
      sudo chmod -R 755 $ROOT_SHARE_HOME/distro-desktop.git
    fi
     
    if [ ! -d $DEFAULT_HOME/.git ]; then
      mkdir $DEFAULT_HOME/.git
    fi         
	
    if ! findmnt -al | grep -qE "^$DEFAULT_HOME/[.]git[[:blank:]]"; then
      # use sudo to prevent the permission issue:
      sudo mount -o rw,rbind $ROOT_SHARE_HOME/distro-desktop.git/.git $DEFAULT_HOME/.git
      for dir in $ROOT_SHARE_HOME/distro-desktop.git $DEFAULT_HOME; do  
        if ! sudo git --work-tree=$dir --git-dir=$dir/.git diff --quiet; then
          # sudo git --work-tree=$dir --git-dir=$dir/.git reset --recurse-submodules --hard
          # it's not need to use --recurse-submodules, especially when the submodules are mounted
          # from other devices, say, with mount's rbind method, the --recurse-submodules option will 
          # failed in this case. 
          sudo git --work-tree=$dir --git-dir=$dir/.git reset --hard
        fi
      done 
    fi
  fi # $ROOT_SHARE_HOME/distro-desktop.git
fi






# 在 .profile 中运行 inxi 能否检测到 Desktop 的值，
# 是和distro有关的, 故不可靠。so, only run the inxi in xdg autostart scripts.
# 

# 采用这里的方法是可以的：
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









