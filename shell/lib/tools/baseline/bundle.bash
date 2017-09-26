#!/usr/bin/env bash

require 'baseline/ruby'

function baseline__bundle__up_to_date_q(){
  require 'env-vars/bundle'
  if [[ ! -e "$PATHS_PROJECT_BUNDLE_INSTALL_FLAG_FILE" ]]; then
    set_baseline_up_to_date_override

    register_baseline_installer_function baseline__bundle__install_bundle

    return 0
  fi
}

function baseline__bundle__install_bundle() {
  require 'wrappers/bundle'
  bundle 'install' '--local'
}


if [[ -n "$AUTO_BOOTSTRAP" && $AUTO_BOOTSTRAP == true ]]; then
  register_baseline_up_to_date_function baseline__bundle__up_to_date_q
fi
