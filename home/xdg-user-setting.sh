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



#  this script is invoked by the following:

# /etc/xdg/autostart/xdg-user-setting.desktop



# https://unix.stackexchange.com/questions/348321/purpose-of-the-autostart-scripts-directory

shopt -s nullglob # Ensure shell expansion with 0 files expands to an empty list, rather than trying to read the "*.sh" file

#if [ -z "$XDG_CONFIG_HOME" ]; then
#    XDG_CONFIG_HOME=~/.config
#fi
#for f in "$XDG_CONFIG_HOME/autostart-scripts/"*.sh; do
#    test -x "$f" && . "$f" || true
#done


if which inxi > /dev/null 2>&1; then 

  # 一些用到的变量：
  data_dir=/home/data
 
  _user=$( ps -o user= -p $$ | awk '{print $1}' )

  # system_uuid
  system_uuid=$( sudo dmidecode -s system-uuid )
  #  root uuid
  root_uuid=$( findmnt -alo TARGET,SOURCE,UUID -M /  | tail -1 | awk ' { print $NF } ' )


  sysinfo_file=/home/$system_uuid-$root_uuid 


  #getent passwd "$_user" | cut -d: -f6
  __home=$( awk -v FS=':' -v user=$_user '$1 == user { print $6}' /etc/passwd ) 


  _distro=$( inxi -c0 -Sxx | grep -Eo 'Distro: [^ ]+' | awk '{ print $2 }' )
  _desktop=$( inxi -c0 -Sxx | grep -Eo 'Desktop: [^ ]+' | awk '{ print $2 }' )

  echo "Distro: $_distro" | sudo tee $sysinfo_file > /dev/null 2>&1 
  echo "Desktop: $_desktop" | sudo tee -a $sysinfo_file > /dev/null 2>&1 
  
  _home=/home/$( awk '/^Distro:/{ a=$2 }/^Desktop:/{ b=$2 }END{ print a"-"b }' $sysinfo_file )
 
  if [ ! -d /home/$_distro-$_desktop ]; then
    sudo mkdir /home/$_distro-$_desktop
    sudo chown -hR $_user:$_user /home/$_distro-$_desktop
  fi


  if [ $__home != $_home ]; then
     sudo mount -o rw,rbind $_home $__home


	if [ -d $data_dir ]; then

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
		find $data_dir/ -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.][^/]*" -printf '%P\n' | awk 'NF > 0' |
		while IFS= read -r line; do
		  if [ ! -d $HOME/"$line" ]; then
		    mkdir $HOME/"$line"
		  fi

		  if ! findmnt -al | grep -qE "^$HOME/$line"; then
		    sudo mount -o rw,rbind $data_dir/"$line" $HOME/"$line"
		  fi

		done


		# dealing on hidden directories except .local:
		find $data_dir/ -maxdepth 1 -type d -regextype posix-extended -regex ".*/[.][^/]*" -printf '%P\n' | awk ' NF > 0 && ! /^[.](local|git)$/' |
		while IFS= read -r line; do
		  if [ ! -d $HOME/"$line" ]; then
		    mkdir $HOME/"$line"
		  fi

		  if ! findmnt -al | grep -qE "^$HOME/$line"; then
		    sudo mount -o rw,rbind $data_dir/"$line" $HOME/"$line"
		  fi

		done

		# dealing on .local:
		if [ -d $data_dir/.local ]; then
			find $data_dir/.local/ -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.][^/]*" -printf '%P\n' | awk 'NF > 0' |
			while IFS= read -r line; do
			  if [ ! -d $HOME/.local/"$line" ]; then
			    mkdir $HOME/.local/"$line"
			  fi

			  if ! findmnt -al | grep -qE "^$HOME/[.]local/$line"; then
			    sudo mount -o rw,rbind $data_dir/.local/"$line" $HOME/.local/"$line"
			  fi

			done
		fi
	       
	fi


   fi



 
#    if [ $_home != /home/$_distro-$_desktop ]; then
#      _home=/home/$_distro-$_desktop
#  
#  
#      # revise the home via /etc/passwd file:
#      # 某些字段可能为空值，故需要相应的考虑。
#      #  
#      # https://en.wikipedia.org/wiki/Name_Service_Switch
#      # https://www.cyberciti.biz/faq/understanding-etcpasswd-file-format/
#      # 
#      
#      sudo sed -Ei "s|^($_user:([^:]*:){4})[^:]*(:.*)$|\1$_home\3|"  /etc/passwd
#      
#    fi

 
fi



# 在 .profile 中运行 inxi 能否检测到 Desktop 的值，
# 是和distro有关的。故不可靠。

# 采用这里的方法是可以的：
# https://unix.stackexchange.com/questions/348321/purpose-of-the-autostart-scripts-directory
#https://specifications.freedesktop.org/autostart-spec/autostart-spec-latest.html



#https://wiki.archlinux.org/index.php/XDG_Base_Directory
#https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html




# 按照这个规范，设定一下相关的变量，就可以同时使用不同的 桌面环境，而保持同样的 home 目录。
#  


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








