#!/usr/bin/env bash

list_files () {
  $(which ls) src/* | xargs realpath
}

install_files () {
  ## install source files
  cp -f $(list_files) "$1"
}

## install
install_files "$1"
