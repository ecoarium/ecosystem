#!/usr/bin/env bash

if [[ -z "$AUTO_BOOTSTRAP" ]]; then
  export AUTO_BOOTSTRAP=true
fi
if [[ -z "$ENABLE_ECOSYSTEM_OVERRIDE" ]]; then
  export ENABLE_ECOSYSTEM_OVERRIDE=true
fi
if [[ -z "$ENABLE_PERSONAL_WORKSPACE_SETTINGS" ]]; then
  export ENABLE_PERSONAL_WORKSPACE_SETTINGS=true
fi

source "$(dirname ${BASH_SOURCE[0]})/../utils/eval-file.bash"

require_relative 'base-variables'

set_ecosystem_variables

set_base_project_workspace_variables
source "$PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_HOME/set.env.bash"

personal_workspace_settings="$PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_HOME/set.personal.env.bash"

if [[ -e "${personal_workspace_settings}" && $ENABLE_PERSONAL_WORKSPACE_SETTINGS == true ]]; then
  source "${personal_workspace_settings}"
fi

function create_personal_workspace_settings(){
  if [[ -e "${personal_workspace_settings}" ]]; then
    fail "you already have a personal workspace settings file: ${personal_workspace_settings}"
  else
    file__write "${personal_workspace_settings}" "#!/usr/bin/env bash

#this file will be sourced immediately after the set.env.bash, located in the same directory
#there are several functions you can implement that will be called at different points in the bootstrap workflow
#  * before_bootstrap
#  * after_bootstrap
#  * before_baseline
#  * after_baseline
#  * before_workspace_settings
#  * after_workspace_settings

"
    good "
your personal workspace settings file was written to: ${personal_workspace_settings}
you can add bash script to this file and it will be run when the project is sourced
"
  fi
}

require_relative "workspace-settings"

require 'terminal'
require 'integrity'
require 'timebomb'

function assert_not_already_loaded() {
	if [[ -n "$PROJECT_LOADED" ]]; then
	  error "
########################################    FAILURE    ##############################################

                    You have already sourced this terminal to a project.
              You cannot source multiple times or from one project to another.
                    The project $PROJECT_NAME has already been sourced.

#####################################################################################################
"
	  return
	fi
}

function bootstrap() {
  assert_not_already_loaded
  function__execute_if_exists 'before_bootstrap'

  require_relative 'baseline'

  local auto_load_bash_source_file_path=''
  for auto_load_bash_source_file_path in `find $ECOSYSTEM_PATHS_SHELL_LIB_HOME/auto_load -type f -iname '*.bash'`; do
  	source "$auto_load_bash_source_file_path"
  done

  bootstrap_workspace_settings

  rename_terminal
  complete_load
  function__execute_if_exists 'after_bootstrap'
}

function complete_load() {
  export PROJECT_LOADED=true
}

if [[ $AUTO_BOOTSTRAP == true ]]; then
  bootstrap
fi
