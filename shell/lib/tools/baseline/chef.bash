#!/usr/bin/env bash

if [[ -z "$ENABLE_BASELINE_WORKSPACE_CHEF" ]]; then
  export ENABLE_BASELINE_WORKSPACE_CHEF=true
fi

require 'baseline/bundle'
require 'baseline/git'

function baseline__chef__up_to_date_q(){
  require 'env-vars/chef'

  baseline__record_baseline_input "${ECOSYSTEM_CHEF_HOME}/**/*"
  baseline__record_baseline_input "${PATHS_PROJECT_WORKSPACE_SETTINGS_CHEF_HOME}/**/*"

  register_baseline_installer_function baseline__chef__install_chef
}

function baseline__chef__install_chef() {
  baseline___state_file_up_to_date_q && return 0

  require 'wrappers/chef'

  chef__configure_workspace
  fail_if "failed to configure workspace with chef-solo"
}

if [[ -n "$AUTO_BOOTSTRAP" && $AUTO_BOOTSTRAP == true && -n "$ENABLE_BASELINE_WORKSPACE_CHEF" && $ENABLE_BASELINE_WORKSPACE_CHEF == true ]]; then
  register_baseline_up_to_date_function baseline__chef__up_to_date_q
fi
