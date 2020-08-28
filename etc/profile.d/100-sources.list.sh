#!/use/bin/env bash

codename=$(lsb_release -sc)
sources_list=/etc/apt/sources.list


if [ ! -e $sources_list ] || ! grep -q -m1 '^deb https://mirrors.tuna.tsinghua.edu.cn/' $sources_list; then
  if lsb_release -i | grep -qi Debian; then
        #https://unix.stackexchange.com/questions/76481/cant-indent-heredoc-to-match-code-blocks-indentation
	cat <<-EOF | gawk 'NR==1 && match($0, /^ +/){n=RLENGTH} {print substr($0, n+1)}' | sudo tee $sources_list >/dev/null
        #http://mirrors.ustc.edu.cn/repogen/
        #https://mirrors.tuna.tsinghua.edu.cn/help/debian/

        #如果遇到无法拉取 https 源的情况，请先使用 http 源并安装：
        #$ sudo apt install apt-transport-https

        deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename main contrib non-free
        deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename main contrib non-free
        deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename-updates main contrib non-free
        deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename-updates main contrib non-free
        deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename-backports main contrib non-free
        # deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename-backports main contrib non-free
        deb https://mirrors.tuna.tsinghua.edu.cn/debian-security $codename/updates main contrib non-free
        deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security $codename/updates main contrib non-free
	EOF
  elif lsb_release -i | grep -qi Ubuntu; then
	cat <<-EOF | gawk 'NR==1 && match($0, /^ +/){n=RLENGTH} {print substr($0, n+1)}' | sudo tee $sources_list >/dev/null
        #http://mirrors.ustc.edu.cn/repogen/
        #https://mirrors.tuna.tsinghua.edu.cn/help/debian/

        #如果遇到无法拉取 https 源的情况，请先使用 http 源并安装：
        #$ sudo apt install apt-transport-https
        	
        deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename main restricted universe multiverse
        deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename main restricted universe multiverse

        deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-security main restricted universe multiverse
        deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-security main restricted universe multiverse
	
        deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-updates main restricted universe multiverse
        deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-updates main restricted universe multiverse
 
        deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-backports main restricted universe multiverse
        deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-backports main restricted universe multiverse
	
        ## Not recommended
        # deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-proposed main restricted universe multiverse
        # deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-proposed main restricted universe multiverse 
	EOF
  fi	
fi



