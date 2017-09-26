#!/usr/bin/env bash

local goody_source_file_path=''
for goody_source_file_path in `find "${ECOSYSTEM_PATHS_SHELL_LIB_HOME}/goodies" -type f -iname '*.bash'`; do
  source "${goody_source_file_path}"
done