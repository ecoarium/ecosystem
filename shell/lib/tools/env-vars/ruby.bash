#!/usr/bin/env bash

export RUBY_VERSION="${RUBY_VERSION:=2.2.4}"
export RUBY_TYPE_NAME="rbenv"

export GEM_HOME="${PATHS_ORGANIZATION_HOME}/.gem-${RUBY_TYPE_NAME}-${RUBY_VERSION}"

export PATH="${GEM_HOME}/bin:${PATH}"

export ECOSYSTEM_PATHS_RUBY_HOME="${ECOSYSTEM_PATHS_HOME}/ruby"

require 'env-vars/bundle'

export RUBYOPT="-I${GEM_HOME}/gems/bundler-${BUNDLER_VERSION}/lib -rbundler/setup"
export RUBYOPT="$RUBYOPT -I${ECOSYSTEM_PATHS_RUBY_HOME}/common/lib -ropt/common"

export SSL_CERT_FILE="${ECOSYSTEM_PATHS_RUBY_HOME}/certs/cacert.pem"

export PATHS_PROJECT_WORKSPACE_SETTINGS_RUBY_HOME="${PATHS_PROJECT_WORKSPACE_SETTINGS_HOME}/ruby"
