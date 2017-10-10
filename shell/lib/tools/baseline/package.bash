#!/usr/bin/env bash

function baseline__package__command() {
  eval "$BASELINE_PACKAGE_MANAGER $@"
}

function baseline__package___set_package_manager() {
  case $OS_NAME in
    Darwin)
      export BASELINE_PACKAGE_MANAGER=brew
      require 'baseline/package/home-brew'
      ;;
    Linux)
      if [[ "$(which yum 2>&1)" ]]; then
        export BASELINE_PACKAGE_MANAGER=yum
      elif [[ "$(which apt 2>&1)" ]]; then
          export BASELINE_PACKAGE_MANAGER=apt
      else
        fail "unsupported OS: $OS_NAME, can't find package manager yum or apt"
      fi
      ;;
    Windows)
      export BASELINE_PACKAGE_MANAGER=pacman
      require 'baseline/package/pacman'
      ;;
    *)
      fail "unsupported OS: $OS_NAME"
      ;;
  esac
}

if [[ -n "$AUTO_BOOTSTRAP" && $AUTO_BOOTSTRAP == true ]]; then
  baseline__package___set_package_manager
fi
