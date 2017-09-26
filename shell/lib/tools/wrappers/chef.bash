#!/usr/bin/env bash

require 'env-vars/chef'
require 'env-vars/berkshelf'

export PATH="$(__DIR__)/chef:$PATH"

function chef__configure_workspace(){
  bundle 'install' '--local'
  sudo__execute_with_administrator_privileges chef-solo -c "${ECOSYSTEM_CHEF_HOME}/solo.rb" -j "${ECOSYSTEM_CHEF_HOME}/node.json"  "${*}"
  local chef_exit_code=$?
   if [[ $chef_exit_code == 0 ]]; then
    set_integrity
  fi
  fail_if "Failed to configure workspace" $chef_exit_code
}
