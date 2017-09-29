#!/usr/bin/env bash

require 'env-vars/ruby'
require 'wrappers/bundle'

function ruby(){
	bundle 'install' '--local'

  $RUBY_BIN "$@"
  fail_if "Failed to execute: ruby ${*}"

  rename_terminal
}

function ruby__init() {
  type rbenv 2>&1 1>/dev/null || return 1

  eval "$(rbenv init - )"
  fail_if "unable to initialize rbenv"
}

function ruby__load_shell() {
  ruby__init || return 1

  local ruby_instalations=($(rbenv versions))

  contains 'ruby_instalations' "$RUBY_VERSION" || return 1

  rbenv shell $RUBY_VERSION
  fail_if "unable set ruby version with rbenv"

  export RUBY_BIN=$(which ruby)
  return 0
}

function ruby__rehash() {
  rbenv rehash
}

ruby__load_shell

function ruby__add_ecosystem_gems_to_path() {
  for dir in $(find "${ECOSYSTEM_PATHS_RUBY_HOME}" -name bin -type d) ; do
    export PATH="$dir:$PATH"
  done
}
ruby__add_ecosystem_gems_to_path

function ruby__add_workspace_gems_to_path() {
	if [[ -e "${PATHS_PROJECT_WORKSPACE_SETTINGS_RUBY_HOME}" ]]; then
	  for dir in $(find "${PATHS_PROJECT_WORKSPACE_SETTINGS_RUBY_HOME}" -name bin -type d) ; do
	    export PATH="$dir:$PATH"
	  done
	fi
}
ruby__add_workspace_gems_to_path
