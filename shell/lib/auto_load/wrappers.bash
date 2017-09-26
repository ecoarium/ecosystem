#!/usr/bin/env bash

local wrapper_source_file_path=''
for wrapper_source_file_path in `find "${ECOSYSTEM_PATHS_SHELL_LIB_HOME}/tools/wrappers" -type f -iname '*.bash'`; do
  source "${wrapper_source_file_path}"
done