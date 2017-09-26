#!/usr/bin/env bash

require 'baseline/package'

function baseline__ruby__up_to_date_q(){
  require 'wrappers/ruby'

  if ! ruby__load_shell ; then
    set_baseline_up_to_date_override

    register_baseline_installer_function baseline__ruby__install_ruby

    return 0
  fi
}

function baseline__ruby__install_ruby() {
  if [[ ! $(type rbenv) ]]; then
    baseline__package__command install rbenv
    fail_if "failed to install rbenv"
  fi

  if [[ ! $(type ruby-build) ]]; then
    baseline__package__command install ruby-build
    fail_if "failed to install ruby-build"
  fi

  ruby__init

  rbenv install "$RUBY_VERSION"
  fail_if "failed to install ruby $RUBY_VERSION"

  ruby__load_shell
  fail_if "failed to load rbenv shell"
}


if [[ -n "$AUTO_BOOTSTRAP" && $AUTO_BOOTSTRAP == true ]]; then
  register_baseline_up_to_date_function baseline__ruby__up_to_date_q
fi
