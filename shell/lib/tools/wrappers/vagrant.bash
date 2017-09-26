#!/usr/bin/env bash

require 'env-vars/vagrant'
require 'env-vars/berkshelf'
require 'wrappers/bundle'

function vagrant(){
 	bundle 'install' '--local'

  cd "$PATHS_PROJECT_DEPLOY_VAGRANT_CONTEXT_HOME"

 	"$(gem_bin_path 'vagrant' 'vagrant')" "$@"
  local vagrant_exit_code=$?

  cd $OLDPWD

  fail_if "Failed to execute: vagrant ${*}" $vagrant_exit_code

  rename_terminal
}

