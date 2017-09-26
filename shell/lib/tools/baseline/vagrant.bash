#!/usr/bin/env bash

require 'baseline/bundle'

function baseline__vagrant__up_to_date_q(){
  require 'env-vars/vagrant'

  local vagrant_boxes_dir="${VAGRANT_HOME}/boxes"
  local vagant_shared_boxes_dir="${HOME}/.vagrant.d.boxes"
  if [[ ! -e "${vagant_shared_boxes_dir}" || ! -e "${vagrant_boxes_dir}" || ! "$(uname -s)" =~ "MSYS*" && ! -d "${vagrant_boxes_dir}" ]]; then
    set_baseline_up_to_date_override

    register_baseline_installer_function baseline__vagrant__install_vagrant

    return 0
  fi
}

function baseline__vagrant__install_vagrant() {
  local vagrant_boxes_dir="${VAGRANT_HOME}/boxes"
  local vagant_shared_boxes_dir="${HOME}/.vagrant.d.boxes"

  if [[ ! -e "${vagant_shared_boxes_dir}" ]]; then
    mkdir -p "${vagant_shared_boxes_dir}"
    fail_if "failed to create directory: ${vagant_shared_boxes_dir}"
  fi

  if [[ ! -e "${VAGRANT_HOME}" ]]; then
    mkdir -p "${VAGRANT_HOME}"
    fail_if "failed to create directory: ${VAGRANT_HOME}"
  fi


  local OS_NAME="$(uname -s)"
  case $OS_NAME in
    Darwin)
      ln -s -f "${vagant_shared_boxes_dir}/" "${vagrant_boxes_dir}"
      ;;
    Linux)
      ln -s -f "${vagant_shared_boxes_dir}/" "${vagrant_boxes_dir}"
      ;;
    MSYS*)
      cmd <<< "mklink /d \"${vagrant_boxes_dir}\" \"${vagant_shared_boxes_dir}/\""
      ;;
    *)
      fail "unsupported OS: $OS_NAME"
      ;;
  esac

  fail_if "failed to create symbolic link from: ${vagant_shared_boxes_dir}"
}


if [[ -n "$AUTO_BOOTSTRAP" && $AUTO_BOOTSTRAP == true ]]; then
  register_baseline_up_to_date_function baseline__vagrant__up_to_date_q
fi
