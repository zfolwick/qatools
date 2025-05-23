#!/usr/bin/env bash
# read in config file.  First look for a local config, then look in the
# ~/.local/bin directory, then look in the $HOME directory

#INSTALL_DIRECTORY="$HOME"/.local/bin
INSTALL_DIRECTORY=.

if [[ -f ./.qaconfig ]]; then
  config_file="./.qaconfig"
elif [[ -f "$HOME/.local/bin/.qaconfig" ]]; then
  config_file="$HOME/.local/bin/.qaconfig"
elif [[ -f "$HOME/.qaconfig" ]]; then
  config_file="$HOME/.qaconfig"
else
  echo "missing .qaconfig file"
fi

current_section=""
 
while IFS= read -r line; do
  # Skip comments and empty lines
  if [[ -z "$line" || "$line" == "#"* ]]; then
    continue
  fi

    # Check for section header
  if [[ "$line" == "["*"]" ]]; then
    current_section="${line//[\[\]]/}" # Extract section name
    continue
  fi

   # Process key-value pairs within a section
  if [[ -n "$current_section" ]]; then
    IFS="=" read -r key value <<< "$line"
    [ -z $key ] && echo "key not set in .qaconfig" && exit 1

    key=$(echo "$key" | sed 's/ //g') #Remove spaces from key
    value=$(echo "$value" | sed 's/^ .* $//g') #Remove leading and trailing spaces from value
    # Perform actions based on section and key-value pairs
    export "$key"="$value"
  fi
done < $config_file
 
usage() {
  echo "search.sh - searches registered external services on the terminal.
 
   A number of use cases require rapid searching of a term.  Searching via the
   terminal could speed up over GUI operations. For example, with Jira, a test
   case ID is the preferred search term. This relies on a jira api token. This
   api token can be generated by the user and stored in your .qaconfig file
 
   -h|--help       displays help
   jira       queries jira with a single word, returning the bugs associated with that word
   testrail   queries testrail with a test case id
 
 
   configuration
 
   for Jira access, add the following into your .qaconfig file
     [jira]
       JIRA_TOKEN=your-jira-token
       JIRA_PROJECT_TEXT="project%20%3D%20AOTA%20OR%20project%20%3D%20OWS%20"
       JIRA_URL=https://your-domain/rest/api/2/search
 
   and then typing \`./search.sh jira --query=TEST_CASE_NUMBER --type=Bug\` will
   present you with the bug numbers present in the AOTA and OWS jira boards.
   Adding more functionality consists of adding additional scripts in the
   qa_search/ directory prepended with \"search_\" and appended with \".sh\"
   (currently, I'm assuming a bash script is launching this, but there's
   nothing stopping you from writing a data provider in another language).
   "
  exit $1
}

options=()
for data_provider_files in $(ls "$INSTALL_DIRECTORY"/qa_search/); do
 source "$INSTALL_DIRECTORY"/qa_search/"${data_provider_files}"
  tail=${data_provider_files#*_}
  data_provider=${tail%.sh}
  options+=($data_provider)
done

case "${1}" in
  -h|--help)
    usage 0
    shift
    ;;
esac
  
for opt in ${options[@]}; do
  if [[ $1 != $opt ]]; then
    continue
  fi
  shift
  search_"${opt}" $@
  shift
  exit 0
done
