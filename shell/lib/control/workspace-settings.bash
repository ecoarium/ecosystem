#!/usr/bin/env bash

export WORKSPACE_SETTINGS_FUNCTION_PREFIX='set_workspace_settings_to_'
export WORKSPACE_SETTINGS_POST_HOOK_FUNCTION_PREFIX='workspace_settings_post_hook_'
export WORKSPACE_SESSION_STATE_FILE="${PATHS_TMP_DIR}/workspace_session_state.json"

export WORKSPACE_SETTING_NAMES=()
export WORKSPACE_SETTING_ENVIRONMENT_VARIABLES=()
export REQUIRED_WORKSPACE_SETTING_ENVIRONMENT_VARIABLES=()

function validate_required_workspace_setting_environment_variables() {
  local var_name=''
  for var_name in "${REQUIRED_WORKSPACE_SETTING_ENVIRONMENT_VARIABLES[@]}" ; do
    variable__exist_q "$var_name"
    fail_if "required environment variable $var_name not set by $WORKSPACE_SETTING"
  done
}

function reset_workspace_setting_environment_variable(){
  local index=''
  for index in ${!WORKSPACE_SETTING_ENVIRONMENT_VARIABLES[@]}
  do
    eval "unset ${WORKSPACE_SETTING_ENVIRONMENT_VARIABLES[$index]}"
  done
}

function record_additional_workspace_setting_environment_variable() {
  WORKSPACE_SETTING_ENVIRONMENT_VARIABLES+=("$1")
}

function register_workspace_setting() {
  WORKSPACE_SETTING_NAMES+=("$1")
}

function show_workspace_settings() {

	good "

######################################    $(echo "${WORKSPACE_SETTING}" | awk '{print toupper($0)}') WORKSPACE SETTINGS    #####################################"

  if [[ $DEBUG == true ]]; then
    debug "
"
    local env_key=''
    for env_key in "${REQUIRED_WORKSPACE_SETTING_ENVIRONMENT_VARIABLES[@]}"
    do
      debug "     $(printf "%-24s %s\n" $env_key): ${!env_key}"
    done


    local env_key=''
    for env_key in "${WORKSPACE_SETTING_ENVIRONMENT_VARIABLES[@]}"
  	do
  		debug "     $(printf "%-24s %s\n" $env_key): ${!env_key}"
  	done
    
    debug "
"
  fi

  good "
     Vagrantfile:
       ${PATHS_PROJECT_DEPLOY_VAGRANT_CONTEXT_VAGRANTFILE}

     Possible Rake files:
       ${PATHS_PROJECT_WORKSPACE_SETTINGS_RAKE_LIB_TASKS_HOME}/vagrant/${VAGRANT_DEFAULT_PROVIDER}/tasks.rb
       ${PATHS_PROJECT_WORKSPACE_SETTINGS_RAKE_LIB_TASKS_HOME}/vagrant/${VAGRANT_CONTEXT}/tasks.rb"


  local hat=''
  for hat in ${HATS//:/$'\n'}
  do
      good "       ${PATHS_PROJECT_WORKSPACE_SETTINGS_RAKE_LIB_TASKS_HOME}/hat/${hat}.rb"
  done

  local test_type=''
  for test_type in ${TEST_TYPES//:/$'\n'}
  do
      good "       ${PATHS_PROJECT_WORKSPACE_SETTINGS_RAKE_LIB_TASKS_HOME}/test/${test_type}.rb"
  done

  good "
     to change the workspace settings execute the following in your terminal:

        change_workspace_setting

     Tips:
        * execute the command 'rake -D' to see a list of available tasks
        * use tab completion with rake task names - 
              (note only required arguments are shown in tab completion)



#####################################################################################################

"
}

function _choose_workspace_settings() {
  while true; do

    choose_message="
#####################################################################################################


     Choose a workspace setting. This will tailor the workspace experience to 
      the activities you perform. You can always change this by executing the
      command change_workspace_setting.

     Please choose from the following options:
"


    echo "$(colorize -t $LIGHT_BLUE "$choose_message")"

  	local count=0
    local workspace_setting_name=''
  	for workspace_setting_name in "${WORKSPACE_SETTING_NAMES[@]}"
		do
			let "count++"
			echo "     $count. $(colorize -t $LIGHT_BLUE $workspace_setting_name)"
		done

    local answer=''
    read -p "    $(colorize -t $LIGHT_BLUE choose) (1-$count)$(colorize -t $LIGHT_BLUE ':') " answer

    local original_answer=$answer
    let "answer--"
    if index_exists $answer WORKSPACE_SETTING_NAMES ; then
    	export WORKSPACE_SETTING="${WORKSPACE_SETTING_NAMES[$answer]}"
    	break
  	else
  		echo "Invalid option: $original_answer"
		fi

  done
}

function change_workspace_setting() {
  unset WORKSPACE_SETTING
  load_workspace_settings
}

function activate_workspace_setting() {
  reset_workspace_setting_environment_variable

  export PATHS_PROJECT_DEPLOY_VAGRANT_HOME="${PATHS_PROJECT_DEPLOY_HOME}/vagrant"
  
  eval "${WORKSPACE_SETTINGS_FUNCTION_PREFIX}${WORKSPACE_SETTING}"

  validate_required_workspace_setting_environment_variables

  export PATHS_PROJECT_DEPLOY_VAGRANT_LIB="${PATHS_PROJECT_DEPLOY_VAGRANT_HOME}/lib"
  export PATHS_PROJECT_DEPLOY_VAGRANT_CONTEXT_HOME="${PATHS_PROJECT_DEPLOY_VAGRANT_HOME}/${VAGRANT_CONTEXT}"
  export PATHS_PROJECT_DEPLOY_VAGRANT_STATE="${PATHS_PROJECT_DEPLOY_VAGRANT_CONTEXT_HOME}/.vagrant"
  export PATHS_PROJECT_DEPLOY_VAGRANT_CONTEXT_VAGRANTFILE="${PATHS_PROJECT_DEPLOY_VAGRANT_CONTEXT_HOME}/Vagrantfile"

  export VAGRANT_VAGRANTFILE="${PATHS_PROJECT_DEPLOY_VAGRANT_CONTEXT_VAGRANTFILE}"
  
  fail_if "unable to activate workspace ${WORKSPACE_SETTING}"

  rename_terminal
  show_workspace_settings

  function__execute_if_exists "${WORKSPACE_SETTINGS_POST_HOOK_FUNCTION_PREFIX}${WORKSPACE_SETTING}"
}

function bootstrap_workspace_settings() {
  REQUIRED_WORKSPACE_SETTING_ENVIRONMENT_VARIABLES=()
  WORKSPACE_SETTING_NAMES=()

  local required_variable=''
  for var_name in VAGRANT_DEFAULT_PROVIDER VAGRANT_CONTEXT TEST_TYPES HATS ;
  do
    REQUIRED_WORKSPACE_SETTING_ENVIRONMENT_VARIABLES+=("$var_name")
  done

  local workspace_setting_bash_source_file_path=''
  for workspace_setting_bash_source_file_path in `find "${PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_CHOICES_HOME}" -type f -iname '*.bash'`; do
    builtin source "$workspace_setting_bash_source_file_path"
  done

  load_workspace_settings
}

function load_workspace_settings() {
  if [[ -z "$WORKSPACE_SETTING" ]]; then
    _choose_workspace_settings
  fi
  
  function__execute_if_exists 'before_workspace_settings'
  activate_workspace_setting
  function__execute_if_exists 'after_workspace_settings'
}
