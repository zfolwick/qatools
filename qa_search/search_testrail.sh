#!/usr/bin/env bash


testrail_usage() {
  echo "search testrail - by id
>./search.sh testrail -c|--case=TEST_CASE_ID [--verbose|-vvv|--pretty|--raw|--help]
"
}

help() {
  testrail_usage

  echo "
  -c|--case           the test case id to query
  -s|--steps          displays the test steps and expectations
  -r|--raw            displays unfiltered, raw json response
  -v|--verbose        display the query url
  -p|--pretty         format the response using jq
  -h|--help           display this menu
  -vvv                display the whole response
  "
  exit 1
}

search_testrail() {
  [ -z "$TESTRAIL_USERNAME" ] && echo add TESTRAIL_USERNAME to .qaconfig file && exit 1
  [ -z "$TESTRAIL_PASSWORD" ] && echo add TESTRAIL_PASSWORD to .qaconfig file && exit 1
  [ -z "$TESTRAIL_URL" ] && echo add TESTRAIL_URL to .qaconfig file && exit 1
  [ -z $1 ] && echo "add a test case id" && testrail_usage && exit 1

  local echo_verbose=false
  local pretty=false
  local echo_query_url=false
  local query=""
  local raw=false
  local display_steps=false

  until test $# -eq 0  ; do
    case $1 in
      -c*|--case*)
        id=$1
        query="${id#*=}"
        shift
        ;;
      -s|--steps)
        display_steps=true
        shift
        ;;
      -v|--verbose) 
        echo_query_url=true
        shift
        ;;
      -vvv)
        echo_verbose=true
        shift
        ;;
      -p|--pretty)
        pretty=true
        shift
        ;;
      -r|--raw)
        raw=true
        shift
        continue
        ;;
      -h|--help)
        help 0
      ;;
      *)
        help 1
    esac
  done
  [[ -z $query ]] && echo "test case id not set" && help 1

  query_url="$TESTRAIL_URL?$TESTRAIL_ENDPOINT$query"

  response=$(curl -s --request GET $query_url -H "Content-Type: application/json" -u "$TESTRAIL_USERNAME:$TESTRAIL_PASSWORD")

  [[ $response =~ "Error" ]] && echo "something wrong with the query" && echo $response

  if $echo_verbose; then
    echo $query_url
    echo $response 
    exit 0
  fi

  if $echo_query_url; then
    echo $query_url
    echo $response | jq '{"priority_id", "suite_id"}'
    exit 0
  fi

  if $display_steps; then
    echo $response | jq "$TESTRAIL_PRETTY_FILTER" | jq '.. | objects | { step: .step | select(.), expect: .expect } | "\(.step) >> \(.expect)"'
    exit 0
  fi

  if $pretty; then
    jq_pretty_script="$TESTRAIL_PRETTY_FILTER"
    echo $response | jq $jq_pretty_script
    exit 0
  fi

  if $raw; then
    echo $response
    exit 0
  fi

  echo $response
}

