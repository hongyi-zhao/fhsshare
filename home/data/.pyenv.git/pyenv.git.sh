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


if [ ! -d $HOME/.pyenv ]; then
  mkdir $HOME/.pyenv
fi

ln -sf $topdir/cache $HOME/.pyenv/

find $topdir/pyenv.git/ -maxdepth 1 -type d -regextype posix-extended -regex ".*/[^.][^/]*$" -printf "%P\n" | 
while IFS= read -r line; do
  ln -sf $topdir/pyenv.git/$line $HOME/.pyenv/
done





