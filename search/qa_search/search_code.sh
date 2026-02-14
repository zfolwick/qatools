#!/usr/bin/env bash

code_usage() {
  echo "> search code PATH PATTERN [--help]"
}

code_help() {
  echo "recursively searches the current directory and subdirectories for a
  regular expression using the configured tool of your choice"
  code_usage


  echo "
  Not intended to replace grep, ag, git grep, ripgrep, or any other tool.
  Offers a unified interface, allowing for fast search for configured
  environments.
  "

  exit $1
}

search_code () {
  [ -z "$SEARCH_TOOL" ] && echo "set the SEARCH_TOOL variable in the .qaconfig directory" && code_usage && exit 1

  until test $# -eq 0  ; do
    case "$1" in
      -h|--help)
        code_help 0
    esac
  done
  local searchtool="$SEARCH_TOOL"

  # override config file defined searches with whatever the user enters in the terminal
  if [ -d $1 ]; then
    : "${SEARCH_TOOL/PATH/$1} ${SEARCH_OPTIONS}"
    search_command="${_/PATTERN/$2}"

  # use the config file and search for the expected PATTERN
  elif [ -d "${SEARCH_PATH/\~/$HOME}" ]; then
    : "${SEARCH_TOOL/PATH/"${SEARCH_PATH/\~/$HOME}"} "
    search_command="${_/PATTERN/$1}"

  else
    echo "code PATH not configured in .qaconfig or passed in via command line."
    code_usage
    exit 1

  fi

  # display the search term as entered so the user can specialize it as needed.
  # TODO: add -s flag to suppress this?  suppress by default?
  echo $search_command
  eval "$search_command"
}
