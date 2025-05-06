#!/usr/bin/env bash

code_usage() {
  echo "recursively searches the current directory and subdirectories for a regular expression using the configured tool of your choice
  > search code [pattern] [ directory to begin searching in ]
  "

}

code_help() {
  code_usage


  echo "
  "

  exit $1
}

search_code () {
  [ -z "$SEARCH_TOOL" ] && echo "set the SEARCH_TOOL variable in the .qaconfig directory" && code_usage && exit 1

  local searchtool="$SEARCH_TOOL"

  search_command="${searchtool/\$SEARCH_PATH/$1}"
  search_command="${search_command/\$PATTERN/$2}"
  eval $search_command
}
