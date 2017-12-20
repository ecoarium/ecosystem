#!/usr/bin/env bash

export PATH="$(__DIR__)/bin:${PATH}"

function show_lines() {
  local file_path="$1"
  local begining_line_number="$2"
  local end_line_number="$3"

  if [[ -z "$end_line_number" ]]; then
    end_line_number="$begining_line_number"
    begining_line_number="1"
  else
    begining_line_number="$(($end_line_number - ($begining_line_number - 1)))"
  fi

  head -n $end_line_number "${file_path}" | tail -r | head -n $begining_line_number | tail -r
}

function var_like() {
  local partial_name="$1"

  eval "local var_names=(\${!${partial_name}*})"

  echo -e "\n"
  for var_name in ${var_names[@]} ; do
    echo "$var_name : '${!var_name}'"
  done
  echo -e "\n"
}

function cookbook_path() {
  if [[ -z "$1" ]]; then
    fail "the cookbook name argument is required, version is optional(if not specified the version in the lock file will be used):
cookbook_readme [cookbook_name] [cookbook_version]"
  fi
  local cookbook_name="$1"
  local cookbook_version="$2"
  local berkshelf_cookbook_path="${BERKSHELF_PATH}/cookbooks"

  local cookbook_dir_path=

  if [[ -n "$cookbook_version" ]]; then
    local cookbook_dir_path="${berkshelf_cookbook_path}/${cookbook_name}-${cookbook_version}"
  fi

  if [[ ! -e "${cookbook_dir_path}" ]]; then
    local cookbook_local_path="$(grep -A0 $cookbook_name ${PATHS_PROJECT_DEPLOY_VAGRANT_CONTEXT_HOME}/*.lock | grep path | awk '{print $2}')"
    if [[ -n "${cookbook_local_path}" ]]; then
      local cookbook_dir_path="$(absolute_path ${berkshelf_cookbook_path}/${cookbook_local_path})"
    fi
  fi

  if [[ ! -e "${cookbook_dir_path}" ]]; then
    local cookbook_version="$(egrep "$cookbook_name\s+\(\d" ${PATHS_PROJECT_DEPLOY_VAGRANT_CONTEXT_HOME}/*.lock | awk '{print $2}')"
    local cookbook_dir_path="${berkshelf_cookbook_path}/${cookbook_name}-${cookbook_version}"
  fi

  if [[ ! -e "${cookbook_dir_path}" ]]; then
    local cookbook_version="$(grep -A2 "$cookbook_name$" ${PATHS_PROJECT_DEPLOY_VAGRANT_CONTEXT_HOME}/*.lock | grep revision | awk '{print $2}')"
    local cookbook_dir_path="${berkshelf_cookbook_path}/${cookbook_name}-${cookbook_version}"
  fi

  if [[ ! -e "${cookbook_dir_path}" ]]; then
    fail "could not find the cookbook ${cookbook_name} version ${cookbook_version}"
  fi

  echo "${cookbook_dir_path}"
}

function cookbook_readme() {
  if [[ -z "$1" ]]; then
    fail "the cookbook name argument is required, version is optional(if not specified the version in the lock file will be used):
cookbook_readme [cookbook_name] [cookbook_version]"
  fi

  local cookbook_readme_path="$(cookbook_path ${*})/README.md"

  if [[ ! -e "${cookbook_readme_path}" ]]; then
    fail "could not find a README.md for cookbook ${cookbook_name} version ${cookbook_version}"
  fi

  atom "${cookbook_readme_path}"
}

function open_cookbook() {
  open "$(cookbook_path ${*})"
}

function atom_cookbook() {
  atom "$(cookbook_path ${*})"
}

function search_cookbook() {
  if [[ "${@: -1}" =~ ^[0-9]+ ]]; then
    local cookbook_version="${@: -1}"
    set -- "${@:1:$(($#-1))}"
  fi

  local cookbook_name="${@: -1}"
  set -- "${@:1:$(($#-1))}"

  eval "search ${*} $(cookbook_path $cookbook_name $cookbook_version)"
}

function gem_path() {
  if [[ -z "$1" ]]; then
    fail "one argument is required: gem_name"
  fi
  local gem_name="$1"
  local gem_which="$(gem which $gem_name -sb false)"

  echo "$(absolute_path "$(dirname "${gem_which}")/..")"
}

function open_gem() {
  if [[ -z "$1" ]]; then
    fail "one argument is required: gem_name"
  fi

  open "$(gem_path "$1")"
}

function atom_gem() {
  if [[ -z "$1" ]]; then
    fail "one argument is required: gem_name"
  fi

  atom "$(gem_path "$1")"
}

function search_gem() {
  local gem_name="${@: -1}"
  set -- "${@:1:$(($#-1))}"

  eval "search ${*} $(gem_path ${gem_name})"
}

function search_ecosystem() {
  eval "search ${*} ${ECOSYSTEM_PATHS_HOME}"
}

function wear_hat() {
  export HATS=$1:$HATS
}

function take_off_hat() {
  export HATS=${HATS/:$1/}
}
