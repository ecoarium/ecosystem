#!/usr/bin/env bash

local organism_source_file_path=''
for organism_source_file_path in `find "${PATHS_PROJECT_WORKSPACE_SETTINGS_ORGANISMS_HOME}" -type f -iname 'organism.bash'`; do
  source "${organism_source_file_path}"
done
