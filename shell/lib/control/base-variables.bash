#!/usr/bin/env bash

function set_ecosystem_variables() {
  export TERM=xterm-256color
  export DELIMITER='-.-'

  local lib_directory_path=''
  for lib_directory_path in "${ECOSYSTEM_PATHS_SHELL_LIB_HOME}"/*/ ; do
    if [[ "$(basename "${lib_directory_path}")" != "auto_load" ]]; then
      add_directory_to_load_path "${lib_directory_path}"
    fi
  done
}

function set_base_project_workspace_variables() {
  set_unless PATHS_PROJECTS_ROOT "${HOME}/Projects"
  set_unless COMPANY_NAME 'github'

  if [[ -z "$PROJECT_NAME" || -z "$ORGANIZATION_NAME"  || -z "$COMPANY_NAME" ]]; then
    fail "the environment variables are required:
 * PROJECT_NAME       -> '$PROJECT_NAME'
 * ORGANIZATION_NAME  -> '$ORGANIZATION_NAME'
 * COMPANY_NAME       -> '$COMPANY_NAME'
"
  fi

  set_unless PATHS_COMPANY_HOME "${PATHS_PROJECTS_ROOT}/$COMPANY_NAME"
  set_unless PATHS_ORGANIZATION_HOME "${PATHS_COMPANY_HOME}/$ORGANIZATION_NAME"

  set_unless PATHS_PROJECT_HOME "$(absolute_path "$(dirname "${BASH_SOURCE[2]}")")"

  ecosystem_override="${PATHS_PROJECT_HOME}/.ecosystem.overrides"
  if [[ -e "${ecosystem_override}" && $ENABLE_ECOSYSTEM_OVERRIDE == true ]]; then
    source "${ecosystem_override}"
  fi

  set_unless PATHS_PROJECT_SCRATCH_HOME "${PATHS_PROJECT_HOME}/scratch"
  set_unless PATHS_PROJECT_SCRATCH_LIB_HOME "${PATHS_PROJECT_SCRATCH_HOME}/lib"
  set_unless PATHS_PROJECT_SCRATCH_RAKE_HOME "${PATHS_PROJECT_SCRATCH_HOME}/rake"

  set_unless PATHS_PROJECT_WORKSPACE_SETTINGS_HOME "${PATHS_PROJECT_HOME}/workspace-settings"

  set_unless PATHS_PROJECT_WORKSPACE_SETTINGS_ORGANISMS_HOME "${PATHS_PROJECT_WORKSPACE_SETTINGS_HOME}/organisms"

  set_unless PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_HOME "${PATHS_PROJECT_WORKSPACE_SETTINGS_HOME}/shell"
  set_unless PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_CHOICES_HOME "${PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_HOME}/choices"
  set_unless PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_TOOLS_HOME "${PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_HOME}/tools"
  set_unless PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_BASELINE_HOME "${PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_TOOLS_HOME}/baseline"
  set_unless PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_GOODIES_HOME "${PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_HOME}/goodies"
  set_unless PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_UTILS_HOME "${PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_HOME}/utils"

  add_directory_to_load_path "${PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_TOOLS_HOME}"
  add_directory_to_load_path "${PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_GOODIES_HOME}"
  add_directory_to_load_path "${PATHS_PROJECT_WORKSPACE_SETTINGS_SHELL_UTILS_HOME}"

  set_unless PATHS_PROJECT_DEPLOY_HOME "${PATHS_PROJECT_HOME}/deploy"
  set_unless PATHS_PROJECT_PRODUCTION_HOME "${PATHS_PROJECT_HOME}/production"

  set_unless PATHS_PROJECT_TESTS_HOME "${PATHS_PROJECT_HOME}/tests"
  set_unless PATHS_PROJECT_TESTS_ACCEPTANCE_HOME "${PATHS_PROJECT_TESTS_HOME}/acceptance"
  set_unless PATHS_PROJECT_TESTS_INTEGRATION_HOME "${PATHS_PROJECT_TESTS_HOME}/integration"
  set_unless PATHS_PROJECT_TESTS_PERFORMANCE_HOME "${PATHS_PROJECT_TESTS_HOME}/performance"
  set_unless PATHS_PROJECT_TESTS_SECURITY_HOME "${PATHS_PROJECT_TESTS_HOME}/security"

  set_unless PATHS_PROJECT_JENKINS_HOME "${PATHS_PROJECT_HOME}/jenkins"
  export PATHS_PROJECT_JENKINS_DOWN_STREAM_JOB_PROPERTIES_FILE="${PATHS_PROJECT_JENKINS_HOME}/.build/down_stream_job_properties_file"
  export PATHS_PROJECT_JENKINS_COMMIT_HASH_FILE="${PATHS_PROJECT_JENKINS_HOME}/.build/commit_hash_file"

  set_unless PROJECT_NAME "$(basename "${PATHS_PROJECT_HOME}")"

  set_unless PATHS_TMP_DIR "${PATHS_ORGANIZATION_HOME}/.tmp/${PROJECT_NAME}"
  if [[ ! -d "${PATHS_TMP_DIR}" ]]; then
    mkdir -p "${PATHS_TMP_DIR}"
  fi

  if [[ -n "$JENKINS_HOME" ]]; then
    export JENKINS_SETTINGS_FILE="${PATHS_ORGANIZATION_HOME}/.jenkins/${PROJECT_NAME}/set.env.bash"

    if [[ -e "${JENKINS_SETTINGS_FILE}" ]]; then
      source "${JENKINS_SETTINGS_FILE}"
    fi
  fi

  set_unless GIT_REPO_SERVER_NAME "${DOMAIN_NAME}"
  set_unless GIT_REPO_BASE_URL "https://${GIT_REPO_SERVER_NAME}"
  set_unless GIT_REPO_URL "${GIT_REPO_BASE_URL}/${ORGANIZATION_NAME}/${PROJECT_NAME}.git"
}
