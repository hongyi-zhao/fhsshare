#!/usr/bin/env bash
#https://wiki.archlinux.org/index.php/Locale
#$ sudo locale-gen

#$ sudo egrep -inR 'zh_CN\.UTF-8' /etc/

#https://groups.google.com/forum/#!topic/comp.unix.shell/pooFnicv3G0
#Greping man page without the hyphen (-) in the result.

#Of course, it's fair to complain that this is obnoxiously subtle ;-) And I
#think the "real" answer is just to use "man --no-hyphenation", as someone
#pointed out elsewhere.

#Benjamin 

#You are right (I wasn't thinking). So besides your proposal of using -e it's
#also possible to use the end-of-option variant

#      ... | grep -v -- '-$'

#>     ... | grep -v -e '-$' 

#werner@X10DAi-01:~$ man --nh locale.conf | grep -Eo '/etc/[^ ]+' | sort -u
#/etc/locale.conf
#/etc/locale.conf:
#werner@X10DAi-01:~$ man --nh update-locale | grep -Eo '/etc/[^ ]+' | sort -u
#/etc/default/locale
#/etc/default/locale)
#werner@X10DAi-01:~$ man --nh localectl | grep -Eo '/etc/[^ ]+' | sort -u
#/etc/locale.conf
#/etc/vconsole.conf.

# Addtitional fix operations for already generated config files under /etc.
#$ sudo egrep -nlR 'zh_CN\.UTF-8' /etc/ 2>/dev/null | egrep -v locale\.gen | xargs -n1 -P0 sudo sed -i 's|zh_CN|en_US|'

config_file=/etc/default/locale

if egrep -qm1 'zh_CN' $config_file; then
  realpath -e /etc/default/locale | xargs sudo sed -i 's|zh_CN|en_US|'
fi




