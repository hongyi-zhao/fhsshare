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



# In the following method, the $script_dirname is equivalent to $topdir otained above in this script:
#https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
script_realpath="$( realpath -e -- "${BASH_SOURCE[0]}")"

script_name="${script_realpath##*/}"                      # Strip longest match of */ from start
# Revise, removed the trailling /: 
script_dirname="${script_realpath:0:${#script_realpath} - ${#script_name} - 1}" # Substring from 0 thru pos of filename
script_basename="${script_name%.[^.]*}"                       # Strip shortest match of . plus at least one non-dot char from end
script_extname="${script_name:${#script_basename} + 1}"                  # Substring from len of base thru end
if [[ -z "$script_basename" && -n "$script_extname" ]]; then          # If we have an extension and no base, it's really the base
  script_basename=".$script_extname"
  ext=""
fi

#echo -e "\tscript_realpath  = \"$script_realpath\"\n\tscript_dirname  = \"$script_dirname\"\n\tscript_basename = \"$script_basename\"\n\tscript_extname  = \"$script_extname\""




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



if [ -d /.git ]; then
  sudo git -C / reset --hard
fi



