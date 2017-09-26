#!/usr/bin/env bash

source "$(dirname ${BASH_SOURCE[0]})/colors.bash"

function rename_terminal(){
  echo -n -e "\033]0;${PROJECT_NAME}${DELIMITER}${ORGANIZATION_NAME}\007"
}

rename_terminal

function prompt(){
  local divider=")>"

  local display_directory='~'
  if [[ "${HOME}" != "$(pwd)" ]]; then
    local current_directory="$(basename $(pwd))"
    local parent_directory="$(basename $(dirname $(pwd)))"
    
    display_directory="$parent_directory/$current_directory"
  fi
  
  local color_gradient=(19 20 21 25 26 27 33 39)
  
  local prompt_parts=(
    "[$(date "+%H:%M:%S")]"
    "$PROJECT_NAME"
    "$WORKSPACE_SETTING"
    "$display_directory"
  )
  
  local prompt_text=''

  local count=-1
  for prompt_part in "${prompt_parts[@]}"; do
    count="$((count+1))"
    prompt_text="${prompt_text}$(colorize -e true -t ${color_gradient[$count]} "$prompt_part")"

    count="$((count+1))"
    prompt_text="${prompt_text}$(colorize -e true -t ${color_gradient[$count]} "$divider")"
  done

  export PS1="$prompt_text "
}

export PROMPT_COMMAND="prompt"