#!/usr/bin/env bash

if [[ -z "$ENABLE_BASELINE_WORKSPACE" ]]; then
  export ENABLE_BASELINE_WORKSPACE=true
fi

require 'sudo'

export BASELINE_STATE_FILE="${PATHS_TMP_DIR}/baseline_states"
export BASELINE_TMP_STATE_FILE="${PATHS_TMP_DIR}/baseline_tmp_state"
export BASELINE_UP_TO_DATE_OVERRIDE=false

export BASELINE_INSTALLER_FUNCTIONS=()
export BASELINE_UP_TO_DATE_FUNCTIONS=()

function register_baseline_installer_function() {
  BASELINE_INSTALLER_FUNCTIONS+=("$1")
}

function register_baseline_up_to_date_function() {
  BASELINE_UP_TO_DATE_FUNCTIONS+=("$1")
}

function baseline__record_baseline_input() {
  if [[ -z "$1" ]]; then
    fail "one argument is required: baseline__record_baseline_input [glob]"
  fi
  local temp_ruby_bin=$(which ruby)
  fail_if 'not able to find any ruby installation, at least 1.9 is a prerequisite'

  local ruby_script="
require 'digest/md5'

record_file_path = '${BASELINE_TMP_STATE_FILE}'
glob = '${1}'

open(record_file_path, 'a') {|record_file|
  Dir.glob(glob) {|input_file|
    next if File.directory?(input_file)
    hash = Digest::MD5.hexdigest(File.read(input_file))
    record_file.puts \"#{input_file}:#{hash}\"
  }
}
"

  RUBYOPT='' $temp_ruby_bin -e "$ruby_script"
  fail_if "Failed to record baseline input"
}

function set_baseline_up_to_date_override() {
  local called_by_file="$(basename "${BASH_SOURCE[1]}")"
  local file_ext="${called_by_file#*.}"
  local called_by="${called_by_file/${file_ext}/}"

  warn "${called_by} triggered update baseline"
  export BASELINE_UP_TO_DATE_OVERRIDE=true
}

function baseline___up_to_date_q() {
  rm -f "$BASELINE_TMP_STATE_FILE"

  local baseline_up_to_date_function=''
  for baseline_up_to_date_function in "${BASELINE_UP_TO_DATE_FUNCTIONS[@]}"
  do
    eval "${baseline_up_to_date_function}"
  done

  if [[ -e "${BASELINE_TMP_STATE_FILE}" ]]; then
    baseline__sort_baseline_tmp_state
    baseline__compute_current_hash
  fi

  if [[ $BASELINE_UP_TO_DATE_OVERRIDE == true ]]; then 
    return 1
  elif [[ -e "${BASELINE_STATE_FILE}" && -e "${BASELINE_TMP_STATE_FILE}" ]]; then
    baseline___state_file_up_to_date_q && return 0
  fi
  return 1
}

function baseline___state_file_up_to_date_q() {
  grep -q "${CURRENT_BASELINE_HASH}" "${BASELINE_STATE_FILE}" 2>/dev/null
}

function baseline__sort_baseline_tmp_state() {
  sort -t ':' -k 1,1 -o "${BASELINE_TMP_STATE_FILE}" "${BASELINE_TMP_STATE_FILE}"
}

function baseline__compute_current_hash() {
  local temp_ruby_bin=$(which ruby)
  fail_if 'not able to find any ruby installation, at least 1.9 is a prerequisite'

  local ruby_script="
require 'digest/md5'

puts Digest::MD5.hexdigest(File.read('${BASELINE_TMP_STATE_FILE}'))
"

  export CURRENT_BASELINE_HASH=$(RUBYOPT='' $temp_ruby_bin -e "$ruby_script")
}

function baseline___ensure_baseline_is_met() {
  local baseline_bash_source_file_path=''
  for baseline_bash_source_file_path in ${ECOSYSTEM_PATHS_SHELL_LIB_HOME}/tools/baseline/*.bash ;
  do
    source "${baseline_bash_source_file_path}"
  done

  if [[ -e "${PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_BASELINE_HOME}" ]]; then
    for baseline_bash_source_file_path in ${PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_BASELINE_HOME}/*.bash ;
    do
      source "${baseline_bash_source_file_path}"
    done
  fi

  baseline___up_to_date_q && return 0

  baseline___apply_baseline

  fail_if "failed applying baseline"

  if [[ ! -e "${BASELINE_STATE_FILE}" || ! -n "$(grep "${CURRENT_BASELINE_HASH}" "${BASELINE_STATE_FILE}")" ]]; then
    baseline___save_applied_baseline_to_state_file
    fail_if "failed saving baseline state"
  fi
}

function baseline___apply_baseline() {
  for baseline_installer_function in "${BASELINE_INSTALLER_FUNCTIONS[@]}"
  do
    debug "executing: ${baseline_installer_function}"
    eval "${baseline_installer_function}"
    fail_if "failed to execute ${baseline_installer_function}"
  done
}

function baseline___save_applied_baseline_to_state_file() {
  echo "${CURRENT_BASELINE_HASH}" >> "${BASELINE_STATE_FILE}"
}

if [[ -n "$AUTO_BOOTSTRAP" && $AUTO_BOOTSTRAP == true && -n "$ENABLE_BASELINE_WORKSPACE" && $ENABLE_BASELINE_WORKSPACE == true ]]; then
  function__execute_if_exists 'before_baseline'
  baseline___ensure_baseline_is_met
  function__execute_if_exists 'after_baseline'
fi

