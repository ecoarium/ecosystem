#!/usr/bin/env bash

require 'env-vars/rake'
require 'wrappers/bundle'

function rake(){
  _rake -g "$@"
}

function _rake(){
  bundle 'install' '--local'

  "$(gem_bin_path 'rake' 'rake')" "$@"
  local exit_code=$?

  rename_terminal

  fail_if "Failed to execute: rake ${*}" $exit_code
}

function reset_rake_completion(){
  local rake_task_cache_file_name='rake_task_cache'
  local file_list_cache_file_name='file_list_cache'
  local base_rake_cache_dir="${PATHS_TMP_DIR}/bash_complete/rake/vagrant/${VAGRANT_CONTEXT}/tests/${TEST_TYPES//://}/hats/${HATS//://}"
  local rake_cache_task_cache_file="${base_rake_cache_dir}/${rake_task_cache_file_name}"
  local rake_cache_file_list_cache_file="${base_rake_cache_dir}/${file_list_cache_file_name}"

  if [[ -e "${rake_cache_task_cache_file}" ]]; then
    rm -f "${rake_cache_task_cache_file}"
  fi

  if [[ -e "${rake_cache_file_list_cache_file}" ]]; then
    rm -f "${rake_cache_file_list_cache_file}"
  fi
}

function _rake_complete(){
  local rake_task_cache_file_name='rake_task_cache'
  local file_list_cache_file_name='file_list_cache'
  local base_rake_cache_dir="${PATHS_TMP_DIR}/bash_complete/rake/vagrant/${VAGRANT_CONTEXT}/tests/${TEST_TYPES//://}/hats/${HATS//://}"
  local rake_cache_task_cache_file="${base_rake_cache_dir}/${rake_task_cache_file_name}"
  local rake_cache_file_list_cache_file="${base_rake_cache_dir}/${file_list_cache_file_name}"

  if [[ ! -e "${base_rake_cache_dir}" ]]; then
    mkdir -p "${base_rake_cache_dir}"
  fi

  find "${RAKE_SYSTEM}/lib/tasks/vagrant/${VAGRANT_CONTEXT}" -type f > "${rake_cache_file_list_cache_file}" 2>/dev/null
  find "${RAKE_SYSTEM}/lib/tasks/vagrant/${VAGRANT_DEFAULT_PROVIDER}" -maxdepth 1 -type f  >> "${rake_cache_file_list_cache_file}" 2>/dev/null
  if [[ -e "${PATHS_PROJECT_DEPLOY_VAGRANT_CONTEXT_HOME}" ]]; then
    find "${PATHS_PROJECT_DEPLOY_VAGRANT_CONTEXT_HOME}" -type f | grep -v logs >> "${rake_cache_file_list_cache_file}" 2>/dev/null
  fi

  local test_types_array=(${TEST_TYPES//:/ })

  local test_type=''
  for test_type in "${test_types_array[@]}" ; do
    echo "${RAKE_SYSTEM}/lib/tasks/test/${test_type}.rb" >> "${rake_cache_file_list_cache_file}"
  done

  local hats_array=(${HATS//:/ })

  local hat=''
  for hat in "${hats_array[@]}" ; do
    echo "${RAKE_SYSTEM}/lib/tasks/hat/${hat}.rb" >> "${rake_cache_file_list_cache_file}"
  done

  find "${RAKE_SYSTEM}" -type f | grep -v spec | grep -v 'lib\/tasks' | grep -v 'lib\/templates' >> "${rake_cache_file_list_cache_file}" 2>/dev/null

  local recent="$(ls -t1 ${rake_cache_task_cache_file} `cat ${rake_cache_file_list_cache_file}` 2>/dev/null | head -n 1)"
  if [[ $recent != "${rake_cache_task_cache_file}" ]]; then
     rake --silent -T -A -sb false 2>/dev/null | cut -d " " -f 2 | sed -e 's/[a-z]*_opts//g;s/[a-z]*_opt//g;s/\[\]//g;s/,\]/]/g' > "${rake_cache_task_cache_file}" 2>/dev/null
  fi
  COMPREPLY=($(compgen -W "`cat ${rake_cache_task_cache_file}`" -- ${COMP_WORDS[COMP_CWORD]}))
  return 0
}

complete -o default -o nospace -F _rake_complete rake
