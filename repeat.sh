#!/usr/bin/env bash
# Version: 1239b6207775164bb47700e3d97f3dcbf9169388
# Author: Zachary Folwick
# Date: 21 May 2025

version() {
  local script_name=$(basename $0)
  local author_line=$(grep -n "Author:" $script_name | grep -v "grep" | cut -f1 -d:)
  VERSION=$(tail -n +$author_line $0 | shasum)
  echo $script_name "${VERSION// */}"
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

[[ "$#" < 1 ]] && usage 1

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
    eval "${COMMAND}"
    values+=($?)
    keys+=($i)
  }

  for idx in "${keys[@]}"; do
    echo "run_$idx $values"
  done
}

get_args $@
