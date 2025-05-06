#!/usr/bin/env bash

jira_usage() {
  echo "jira query tool
  > search jira --query=TERM [--type=Bug|Story|Task|Epic]"
}

jira_help() {
  jira_usage
  echo "
  -q|--query            single word jira term to query
  -t|--type             the issue type (Bug,Story,Task,Epic)
  -i|--issues-only      displays associated issue numbers only
  -r|--raw              displays unfiltered, raw json response
  -v|--verbose          display the query url
  -p|--pretty           format the response using jq
  -h|--help             display this menu
  -vvv                  display the whole response
  "
  exit $1
}

search_jira() {
  [[ -z "${JIRA_TOKEN}" ]] && echo "JIRA_TOKEN environment variable is not set. Please set the JIRA_TOKEN" && exit 1
  if [[ "$@" =~ "-h" || "$@" =~ "--help" ]]; then
    jira_help 0
  fi

  [[ $# -lt 1 ]] && echo "need to pass in a search query" && jira_usage

  if ! [[ "$@" =~ "query="[A-Z|a-z|0-9]+ ]]; then
    echo $@
    echo "need to pass in a search query " && exit 1
  fi

  local query_string=""
  local type_string=""
  local echo_verbose=false
  local pretty=false
  local echo_query_url=false
  local raw=false
  local show_associated_issues=false

  until test $# -eq 0  ; do
    case "$1" in
      -q|--query*)
        query_string="${1#*=}"
        shift 
        continue
        ;;
      -t*|--type*)
        type_string="${1#*=}"
        shift
        continue
        ;;
      -i|--issues-only)
        show_associated_issues=true
        shift
        continue
        ;;
      -p|--pretty)
        pretty=true
        shift
        continue
        ;;
      -r|--raw)
        raw=true
        shift
        continue
        ;;
      -h|--help)
        jira_help 0
        ;;
      -v|--verbose)
        echo_query_url=true
        shift
        continue
        ;;
      -vvv)
        echo_verbose=true
        shift
        continue
        ;;
      *)
        jira_help 1
    esac

  done

  #if [ -z $query_string ]; then echo "query not set" && echo "query: ${query_string}" && exit 1 ; fi

  if ! [[ -z $type_string ]]; then 
    issue_type="%20AND%20issuetype=${type_string}" 
  fi

  project_text=$JIRA_PROJECT_TEXT
  query_url="$JIRA_URL$JIRA_ENDPOINT?jql=${project_text}AND%20text%20~%20${query_string}${issue_type}&fields=key"


  if $echo_query_url; then
    echo $query_url
  fi

  response=$(curl -s --request GET $query_url -H 'Authorization: Bearer '$JIRA_TOKEN) 
  [[ $response =~ "Error" ]] && echo "something wrong with the query" && echo $response

  if $raw; then
    echo $response
  fi

  if $echo_verbose; then
    echo $query_url
    echo $response 
    exit 0
  fi

  if $pretty; then
    echo $response | jq 
    exit 0
  fi

  if $show_associated_issues; then
    jq_script=".issues[] | .key"
    associated_bugs=$(echo $response | jq -r "$jq_script")
    echo $associated_bugs
    exit 0
  fi

  echo $response
}

