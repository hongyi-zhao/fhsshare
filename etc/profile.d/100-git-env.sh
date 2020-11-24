#!/usr/bin/env bash

# $ man git | grep -A 20 GIT_DISCOVERY_ACROSS_FILESYSTEM 
#       GIT_DISCOVERY_ACROSS_FILESYSTEM
#           When run in a directory that does not have ".git" repository directory, Git tries to find such a
#           directory in the parent directories to find the top of the working tree, but by default it does not cross
#           filesystem boundaries. This environment variable can be set to true to tell Git not to stop at filesystem
#           boundaries. Like GIT_CEILING_DIRECTORIES, this will not affect an explicit repository directory set via
#           GIT_DIR or on the command line.

export GIT_DISCOVERY_ACROSS_FILESYSTEM=true
export GIT_SSL_NO_VERIFY=1

