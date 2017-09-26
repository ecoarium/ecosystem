#!/usr/bin/env bash


function _subl_path() {
  local file_cache="${PATHS_TMP_DIR}/sublime_bin_path"
  if [[ -f "${file_cache}" ]]; then
    export SUBLIME_BIN=$(cat "${file_cache}")
    return
  fi

  export SUBLIME_BIN="$(system_profiler SPApplicationsDataType | grep -e 'Location: .*Sublime.*.\.app' | awk -F': ' '{print $2}')/Contents/SharedSupport/bin/subl"
  echo "${SUBLIME_BIN}" > "${file_cache}"

  return
}

function subl() {
  if [[ -z "${SUBLIME_BIN}" ]]; then
    _subl_path
  fi

  if [[ -n "${*}" && -t 0 ]]; then
    # if no stdin and arg(s) open arg(s)/file_path(s)

    if [[ -z "$2" && ! -e "$1" ]]; then
      local dir="$(dirname "$1")"
      if [[ ! -e "${dir}" ]]; then
        mkdir -p "${dir}"
      fi
    fi

    subl_open "${*}"

  elif [[ -z "${*}" && ! -t 0 ]]; then
    # if stdin and no args open each line as file path

    local IFS=
    local data=''
    while read file_path ; do
      local dir="$(dirname "${file_path}")"
      if [[ ! -e "${dir}" ]]; then
        mkdir -p "${dir}"
      fi

      subl_open "${file_path}"
    done

  elif [[ -n "$1" && -z "$2" && ! -t 0 ]]; then
    # if stdin and one arg write stdin into arg/file_path and then open file

    local dir="$(dirname "$1")"
    if [[ ! -e "${dir}" ]]; then
      mkdir -p "${dir}"
    fi

    local IFS=
    local data=''
    while read data ; do
      echo "$data" >> "${1}"
    done

    subl_open "$1"
  else
    fail 'Why the face?, did you pass multiple arguments and pipe output to this function?'
  fi
}

function subl_open() {
  "${SUBLIME_BIN}" "${*}"
}

function subl_project() {
  cd "${PATHS_PROJECT_HOME}"
  if [[ -e "$PROJECT_NAME.sublime-project" ]]; then
    subl --project "$PROJECT_NAME.sublime-project"
  else
    subl .
  fi
}
