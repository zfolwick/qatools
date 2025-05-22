#!/usr/bin/env bash
# Version: 29f504155b5a61188b7c8d09534206755949b83e
# Author: Zachary Folwick
# Date: 21 May 2025

version() {
  local author_line=$(grep -n "Author:" $(which $(basename $0)) | grep -v "grep" | cut -f1 -d:)
  VERSION=$(tail -n +$author_line $0 | shasum)
  echo $(basename $0) "${VERSION// */}"
}

usage() {
  echo "./repeat.sh -n [NUM] \"some script\""
  return "$1"
}

help() {
  echo "repeat a given script a given number of times and report output"
  usage 0

  echo "
  Repeats the NUM number of times the script passed to it and stores the exit codes in an array. In Bash, exit codes of 0 are good, nonzero exit codes indicate an issue. This should aid in stability of test scripts.

  -n,--number     the number of times to repeat the script
  -v,--version    the version of the script past line 2
  "
}

[[ "$#" -lt 1 ]] && usage 1

get_args() {
  local NUM

  until test "$#" -eq 0
  do
    case "$1" in
      -n|--number)
        shift
        NUM=$1
        shift
        continue
        ;;
      -h|--help)
        help
        exit 0
        shift
        ;;
      -v|--version)
        version
        exit 0
        ;;
      *) # break out of loop
        COMMAND+=" $1"
        shift
        ;;
    esac
  done

  declare -a values
  declare -a keys
  for ((i=0; i<$NUM; i++)) {
    echo "doing $COMMAND  ..."
    output=$(eval "${COMMAND}")
    values+=($?)
    keys+=($i)
    echo $output > "verification_run_$i.txt"
  }

  for idx in "${keys[@]}"; do
    echo "run_$idx $values"
  done
}

get_args "$@"
