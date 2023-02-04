#!/usr/bin/env bash

# $ man git | grep -A 20 GIT_DISCOVERY_ACROSS_FILESYSTEM 
#       GIT_DISCOVERY_ACROSS_FILESYSTEM
#           When run in a directory that does not have ".git" repository directory, Git tries to find such a
#           directory in the parent directories to find the top of the working tree, but by default it does not cross
#           filesystem boundaries. This environment variable can be set to true to tell Git not to stop at filesystem
#           boundaries. Like GIT_CEILING_DIRECTORIES, this will not affect an explicit repository directory set via
#           GIT_DIR or on the command line.


#https://discourse.gnome.org/t/are-you-sure-you-want-to-proceed-message-on-login/13758/8?u=hongyi-zhao
#$ sudo gedit /etc/gdm3/config-error-dialog.sh

#elif [ -x /usr/bin/zenity ]; then
#        # https://discourse.gnome.org/t/are-you-sure-you-want-to-proceed-message-on-login/13758/5?u=hongyi-zhao
#	zenity --no-markup --warning --no-wrap --text="$TEXT"
#fi


#Got it. In my case, I need to enable the following settings in my profile related scripts to let them work properly:

#git config --global --add safe.directory /
#export GIT_DISCOVERY_ACROSS_FILESYSTEM=true
#export GIT_SSL_NO_VERIFY=1

export GIT_DISCOVERY_ACROSS_FILESYSTEM=true
export GIT_SSL_NO_VERIFY=1

