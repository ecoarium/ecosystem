#!/usr/bin/env bash

export VAGRANT_INTERNAL_BUNDLERIZED=1
export VAGRANT_HOME="${PATHS_ORGANIZATION_HOME}/.vagrant.d"
export VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET=true

export PATHS_ORGANIZATION_VAGRANT_HOME="${VAGRANT_HOME}"

if [[ "$(uname -s)" =~ "MSYS*" ]]; then
  export PATH=/c/Program\ Files/Oracle/VirtualBox:$PATH
fi
