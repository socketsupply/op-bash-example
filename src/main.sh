#!/usr/bin/env bash

pidsfile="/tmp/opfifo-pids"
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
  write "title" "window=0&value=Hello from Bash"
  write "navigate" "window=0&value=file://$dirname/index.html"
  write "menu" "window=0&value=$MENU"

  ## kill previous pids
  killpids
}

io () {
  ## init fifo
  rm -f /tmp/opfifo-{stdin,stdout}
  mkfifo /tmp/opfifo-stdin
  mkfifo /tmp/opfifo-stdout

  {
    while true; do
      if read -r line < /tmp/opfifo-stdout; then
        echo "$line"
      fi
    done
  } &

  pids+=($!)

  echo "${pids[@]}" >> $pidsfile

  while read -r line; do
    log "Forwarding message to FIFO"
    echo "$line" > /tmp/opfifo-stdin
  done
}

signals () {
  trap onsigterm SIGTERM SIGINT
}

signals || return $?
init || return $?
io || return $?

wait
