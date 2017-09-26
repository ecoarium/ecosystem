#!/usr/bin/env bash

function pacman(){
  case $1 in
    install)
      shift
      pacman -S --noconfirm $*
      ;;
    *)
      pacman $*
      ;;
  esac
}