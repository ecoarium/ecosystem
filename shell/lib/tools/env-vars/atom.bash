#!/usr/bin/env bash

export ATOM_BIN=/usr/local/bin/atom

if [[ "$OS_NAME" == 'Windows' ]]; then
  export ATOM_BIN=$HOME/AppData/Local/atom/bin/atom
fi
