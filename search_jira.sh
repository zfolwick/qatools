#!/usr/bin/env bash
usage() {
  echo "jira query tool
  > search jira --query=TERM --type=[Bug,Story,Task,Epic]"
}

help() {
  
  usage
  echo "
 -q,--query       single word jira term to query
 -t,--type        the issue type (Bug,Story,Task,Epic)
 -h,--help        this help screen
 -p,--pretty      formats verbose output for jq
 -v,--verbose     displays the URL search query
 -vvv             displays the whole contents of jira, unfiltered
  "
  exit $1
}

search_jira() {
  if [[ "$@" =~ "-h" || "$@" =~ "--help" ]]; then
    help 0
  fi

  [[ $# -lt 2 ]] && echo "need to pass in a search query and jira ticket type." && usage

  if ! [[ "$@" =~ "query="[A-Z]+ && "$@" =~ "type="[Bug|Story|Epic|Task] ]]; then
    echo $@
    echo "need to pass in a search query and jira ticket type." && exit 1
  fi

  local query_string=""
  local type_string=""
  local echo_verbose=false
  local pretty=false
  local echo_query_url=false

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
      -p|--pretty)
        pretty=true
        shift
        continue
        ;;
      -h|--help)
        help 0
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
        help 1
    esac

    if ! [[ -z $type && -z $query ]]; then break; fi
  done

  if [[ $type_string =~ "--type" ]]; then
    echo "type not set" 
    exit 1
  fi

  if [[ $query_string =~ "--query" ]]; then
    echo "query not set" 
    exit 1
  fi

  if [ -z $type_string ] || [ -z $query_string ]; then echo "query or type not set" && echo "query: ${query_string}; type: ${type_string}" && exit 1 ; fi

  project_text="project%20%3D%20AOTA%20"
  query_url="${JIRA_URL}?jql=${project_text}AND%20text%20~%20${query_string}%20AND%20issuetype=${type_string}&fields=key"

  response=$(curl -s --request GET $query_url -H 'Authorization: Bearer '$JIRA_TOKEN) 

  [[ $response =~ "Error" ]] && echo "something wrong with the query" && echo $response

  if $echo_verbose; then
    echo $query_url
    echo $response 
    exit 0
  fi

  if $pretty; then
    echo $response | jq 
    exit 0
  fi

  associated_bugs=$(echo $response | jq -r '.issues[] | .key' | xargs)

  if $echo_query_url; then
    echo $query_url
    echo $associated_bugs
    exit 0
  fi

  echo $associated_bugs
}

