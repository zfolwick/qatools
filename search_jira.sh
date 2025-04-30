#!/usr/bin/env bash
[[ -z "${JIRA_TOKEN}" ]] && echo "JIRA_TOKEN environment variable is not set. Please set the JIRA_TOKEN" && exit 1

jira_usage() {
  echo "jira query tool
  > search jira --query=TERM --type=[Bug,Story,Task,Epic]"
}

jira_help() {
  jira_usage
  echo "
  -q|--query       single word jira term to query
  -t|--type        the issue type (Bug,Story,Task,Epic)
  -b|--bugs        displays associated bugs
  -r|--raw         displays unfiltered, raw json response
  -v|--verbose     display the query url
  -p|--pretty      format the response using jq
  -h|--help        display this menu
  -vvv             display the whole response
  "
  exit $1
}

search_jira() {
  if [[ "$@" =~ "-h" || "$@" =~ "--help" ]]; then
    jira_help 0
  fi

  [[ $# -lt 2 ]] && echo "need to pass in a search query and jira ticket type." && jira_usage

  if ! [[ "$@" =~ "query="[A-Z|a-z|0-9]+ && "$@" =~ "type="[Bug|Story|Epic|Task] ]]; then
    echo $@
    echo "need to pass in a search query and jira ticket type." && exit 1
  fi

  local query_string=""
  local type_string=""
  local echo_verbose=false
  local pretty=false
  local echo_query_url=false
  local raw=false
  local show_associated_bugs=false

  until test $# -eq 0  ; do
    case "$1" in
      -q|--query*)
        query_string="${1#*=}"
        shift 
        continue
        ;;
      -t|--type*)
        type_string="${1#*=}"
        shift
        continue
        ;;
      -b|--bugs)
        show_associated_bugs=true
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

    if ! [[ -z $type && -z $query ]]; then break; fi
  done

  if [ -z $type_string ] || [ -z $query_string ]; then echo "query or type not set" && echo "query: ${query_string}; type: ${type_string}" && exit 1 ; fi

  project_text=$JIRA_PROJECT_TEXT
  query_url="$JIRA_URL$JIRA_ENDPOINT?jql=${project_text}AND%20text%20~%20${query_string}%20AND%20issuetype=${type_string}&fields=key"


  if $echo_query_url; then
    echo $query_url
  fi

  response=$(curl -s --request GET $query_url -H 'Authorization: Bearer '$JIRA_TOKEN) 

  echo $response

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

  if $show_associated_bugs; then
    associated_bugs=$(echo $response | jq -r '.issues[] | .key' | xargs)
    echo $associated_bugs
    exit 0
  fi

  echo $response
}

