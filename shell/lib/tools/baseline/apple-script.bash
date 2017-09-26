#!/usr/bin/env bash

function baseline__apple_script__get_terminal(){
  local term_program_id=''
  if [[ "$TERM_PROGRAM" == 'Apple_Terminal' ]]; then
    term_program_id='com.apple.Terminal'
  elif [[ "$TERM_PROGRAM" == 'iTerm.app' ]]; then
    term_program_id='com.googlecode.iterm2'
  elif [[ -z "$TERM_PROGRAM" && "$USER" == 'vagrant' ]]; then
    term_program_id='/usr/sbin/sshd'
  elif [[ "$TERM_PROGRAM" == 'idea' ]]; then
    term_program_id='com.idea.termial'
  elif [[ "$TERM_PROGRAM" == 'jenkins' ]]; then
    term_program_id='com.jenkins.termial'
  else
    fail "unknown terminal $TERM_PROGRAM"
  fi
  echo $term_program_id
}

function baseline__apple_script__up_to_date_q(){
  if [[ "$(uname -s)" == "Darwin" ]]; then
    local terminal_found="$(defaults read com.apple.universalaccessAuthWarning 2>&1 | grep "$(baseline__apple_script__get_terminal)")"

    if [[ -z "$terminal_found" ]]; then
      set_baseline_up_to_date_override
      register_baseline_installer_function baseline__apple_script__grant_accessibility_to_term
    fi
  fi
}

function baseline__apple_script__grant_accessibility_to_term() {
  local os_version="$(sw_vers -productVersion)"

  local insert_values=''
  if [[ "${os_version:0:5}" == "10.10" ]];then
    insert_values="VALUES('kTCCServiceAccessibility','$(baseline__apple_script__get_terminal)',0,1,1,NULL)"
  elif [[ "${os_version:0:5}" == "10.11" ]];then
    insert_values="VALUES('kTCCServiceAccessibility','$(baseline__apple_script__get_terminal)',0,1,1,NULL,NULL)"
  else
    warn "this version, ${os_version}, of OSx is not supported. manual configuration via the System Preferences will be necessary for some automation for function..."
    return 0
  fi

  sudo__execute_with_administrator_privileges "sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db \"INSERT INTO access ${insert_values};\""
  fail_if "failed to grant automation access"

  defaults write com.apple.universalaccessAuthWarning $(baseline__apple_script__get_terminal) -bool true
  fail_if "failed to track granting of automation access"
}

if [[ -n "$AUTO_BOOTSTRAP" && $AUTO_BOOTSTRAP == true ]]; then
  register_baseline_up_to_date_function baseline__apple_script__up_to_date_q
fi
