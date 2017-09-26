#!/usr/bin/env bash

require 'logging'
require 'wrappers/ruby'
require 'env-vars/bundle'

function bundle(){
  assert_set_env_is_up_to_date

  _ensure_bundler_installed

  local bundle_command=$1

  if [[ $bundle_command == "install" || $bundle_command == "package" || $bundle_command == "update" ]]; then
    if [[ "$BUNDLE_GEMFILE" -nt "$PATHS_PROJECT_BUNDLE_INSTALL_FLAG_FILE" || "$ECOSYSTEM_BUNDLE_GEMFILE" -nt "$PATHS_PROJECT_BUNDLE_INSTALL_FLAG_FILE" ]]; then

      local OS_NAME="$(uname -s)"
      case $OS_NAME in
        Darwin)
          _bundle config build.nokogiri --with-xml2-include=/usr/local/Cellar/libxml2/2.9.4/include/libxml2/libxml --with-xml2-lib=/usr/local/Cellar/libxml2/2.9.4/lib --with-xslt-dir=/usr/local/Cellar/libxslt/1.1.28_1
          ;;
        *)
          _bundle config build.nokogiri --use-system-libraries
          ;;
      esac

      if [[ $bundle_command == "update" ]]; then
        _bundle update
      elif [[ "$BUNDLE_GEMFILE" -nt "${BUNDLE_GEMFILE}.lock" || "$ECOSYSTEM_BUNDLE_GEMFILE" -nt "${BUNDLE_GEMFILE}.lock" ]]; then
        _bundle package
      else
        _bundle install --local
      fi

      touch $PATHS_PROJECT_BUNDLE_INSTALL_FLAG_FILE
      return 0
    else
      return 0
    fi
  fi

  eval "$RUBY_BIN $BUNDLER_BIN ${*}"
  fail_if "Failed to execute: ${*}"
  return 0
}

function _bundle(){
  cd $PATHS_PROJECT_WORKSPACE_SETTINGS_BUNDLE_HOME

  debug "exec [RUBYOPT='' BUNDLE_BIN_PATH='' $RUBY_BIN $BUNDLER_BIN ${*}] in [$PATHS_PROJECT_WORKSPACE_SETTINGS_BUNDLE_HOME]"

  eval "RUBYOPT='' BUNDLE_BIN_PATH='' $RUBY_BIN $BUNDLER_BIN ${*}" 1>&2
  local bundle_exit_code=$?

  cd $OLDPWD
  fail_if "Failed to execute: [bundle ${*}] in [$PATHS_PROJECT_WORKSPACE_SETTINGS_BUNDLE_HOME]" $bundle_exit_code

  ruby__rehash
}

function _ensure_bundler_installed(){
  if [[ ! -d "$GEM_HOME/gems/bundler-${BUNDLER_VERSION}" ]]; then
    RUBYOPT='' BUNDLE_BIN_PATH='' gem install --local "${ECOSYSTEM_BUNDLE_HOME}/bundler-${BUNDLER_VERSION}.gem"
    fail_if "failed to install bundle gem"
  fi
}

function gem_bin_path() {
  bundle install --local

  RUBYOPT='' $RUBY_BIN -e "puts Gem.bin_path('$1', '$2')"
  fail_if "failed to find gem bin path for $1 $2"
}
