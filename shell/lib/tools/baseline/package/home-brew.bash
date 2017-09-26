#!/usr/bin/env bash

function baseline__home_brew__up_to_date_q(){
  if [[ ! $(which brew) ]] ; then
    set_baseline_up_to_date_override

    register_baseline_installer_function baseline__home_brew__install_home_brew

    return 0
  fi
}

function baseline__home_brew__install_home_brew() {
  local temp_ruby_bin=$(which ruby)
  fail_if 'not able to find any ruby installation, at least 1.9 is a prerequisite'

  RUBYOPT='' $temp_ruby_bin -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fail_if "failed to install home brew"
}

if [[ -n "$AUTO_BOOTSTRAP" && $AUTO_BOOTSTRAP == true ]]; then
  register_baseline_up_to_date_function baseline__home_brew__up_to_date_q
fi

function brew() {
  local brew_bin=$(which brew)  
  RUBYOPT=''  BUNDLE_BIN_PATH='' $brew_bin "$@"
}
