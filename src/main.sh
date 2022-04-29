#!/usr/bin/env bash
##
# `op-bash-example` - A simple Operator Framework example written in Bash that makes use of POSIX Named Pipes for IPC request IO
#
# This file is part of op-bash-example.
#
# MIT License
#
# Copyright (c) 2022 Socket Supply Co.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Socket Supply Co. <socketsupply.co>
##

pidsfile="/tmp/op-bash-pids"
dirname="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck disable=SC2207
pids=($(cat "$pidsfile" 2>/dev/null))

MENU="$(cat <<-MENU
  Program:
    About Program: _
    ---
    Quit: q + CommandOrControl
  ;
MENU
)"

onsigterm () {
  killpids
  exit 0
}

killpids () {
  for pid in "${pids[@]}"; do
    log "Sending SIGTERM to $pid"
    kill -TERM "$pid" 2>/dev/null
  done

  for pid in "${pids[@]}"; do
    log "Sending SIGKILL to $pid"
    kill -9 "$pid" 2>/dev/null
  done

  rm -f "$pidsfile"
}

encode_uri_component () {
  local string="$1"
  local length=${#string}
  local char=""
  local i

  for (( i = 0 ; i < length ; i++ )); do
    char=${string:$i:1}

    case "$char" in
      [-_.~a-zA-Z0-9]) echo -ne "$char" ;;
      *) printf '%%%02x' "'$char" ;;
    esac
  done
}

write () {
  # shellcheck disable=SC2059,SC2068
  printf "ipc://%s?" "$1"
  shift
  local args=()
  # shellcheck disable=SC2001,SC2207
  IFS='&' read -r -d '' -a args < <(echo -ne "$@")

  for (( i = 0; i < ${#args[@]}; ++i )); do
    local arg="${args[$i]}"
    local kv=()
    IFS='=' read -r -d '' -a kv < <(echo -ne "$arg")

    local key="${kv[0]}"
    local value="${kv[1]}"

    echo -ne "$key"
    echo -ne '='
    echo -ne "$(encode_uri_component "$(echo -ne "$value")")"
    printf '&'
  done

  ## flush
  echo
}

log () {
  # shellcheck disable=SC2068
  write "stdout" "value=$*"
}

init () {
  sleep 1s

  ## init window
  write "show" "window=0"
  write "menu" "window=0&value=$MENU"
  write "navigate" "window=0&value=file://$dirname/index.html"

  ## kill previous pids
  killpids
}

io () {
  ## init fifo
  rm -f /tmp/op-bash-{stdin,stdout}
  mkfifo /tmp/op-bash-stdin
  mkfifo /tmp/op-bash-stdout

  {
    while true; do
      if read -r line < /tmp/op-bash-stdout; then
        echo "$line"
      fi
    done
  } &

  pids+=($!)

  echo "${pids[@]}" >> $pidsfile

  while read -r line; do
    log "Forwarding message to FIFO"
    echo "$line" > /tmp/op-bash-stdin
  done
}

signals () {
  trap onsigterm SIGTERM SIGINT
}

signals || return $?
init || return $?
io || return $?

wait
