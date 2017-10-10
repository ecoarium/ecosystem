#!/usr/bin/env bash

function os__name() {
  case "$(uname -s)" in
    Darwin)
      echo 'Darwin'
      ;;
    Linux)
      echo 'Linux'
      ;;
    *)
      debug "not darwin or linux, we assume it's windows..."
      echo 'Windows'
      ;;
  esac
}

export OS_NAME="$(os__name)"
