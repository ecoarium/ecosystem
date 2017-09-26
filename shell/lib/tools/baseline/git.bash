#!/usr/bin/env bash

require 'baseline/package'

function baseline__git__up_to_date_q(){
  if [[ -z "$(git config --global --get credential.helper)" ]]; then
    set_baseline_up_to_date_override

    register_baseline_installer_function baseline__git__configure_credential_helper

    return 0
  fi
}

function baseline__git__configure_credential_helper() {
  local OS_NAME="$(uname -s)"
  case $OS_NAME in
    Darwin)
      git config --global credential.helper osxkeychain
      ;;
    Linux)
      git config --global credential.helper store
      ;;
    MSYS*)
      git fetch
      git config --global credential.helper wincred
      ;;
    *)
      fail "unsupported OS: $OS_NAME"
      ;;
  esac
  fail_if "failed to enable git credential helper"
}

if [[ -n "$AUTO_BOOTSTRAP" && $AUTO_BOOTSTRAP == true ]]; then
  register_baseline_up_to_date_function baseline__git__up_to_date_q
fi
