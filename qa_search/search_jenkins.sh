#!/usr/bin/env bash
jenkins_usage() {
  echo "outputs a set of jenkins build results"
  echo "> jenkins.sh {--build=BUILD_NUMBER} [--status=PASSED|FAIL|SKIPPED|REGRESSION] [--url|--raw|--pretty|--verbose|-vvv]"
}

jenkins_help() {
  jenkins_usage

  echo "
  -b|--build      the build to query against
  -s|--status     when set, filters output by status in jira
  -r|--raw        displays unfiltered, raw json response
  -v|--verbose    display the query url
  -p|--pretty     format the response using jq
  -h|--help       display this menu
  -vvv            display the whole response
  "

  exit $1
}

is_int() { case $1 in ''|*[!0-9]*) return 1;;esac;}

verify_creds() {
  #JENKINS_USER_PASS is an environment variable
  CREDENTIALS=$JENKINS_USER_PASS 
  if [[ ! -n $CREDENTIALS ]]; then
    echo "need \$JENKINS_USER_PASS set in .qaconfig. Place
      JENKINS_USER_PASS=username@starbucks.com:your-password-here"
    jenkins_usage
    exit 1
  fi
}

search_jenkins() {
  verify_creds

  local has_status=false
  local show_url=false
  local show_raw=false
  local pretty=false
  local echo_verbose=false

  until test $# -eq 0  ; do
    case "$1" in
      -b*|--build*)
        if ! is_int "${1#*=}" == "0"; then
          echo "first argument must be the jenkins build number"
          jenkins_help 1
        fi

        build_number="${1#*=}"
        shift
        continue
        ;;
      -s*|--status*)
        has_status=true
        status="${1#*=}"
        shift
        continue
        ;;
      -v|--verbose)
        show_url=true
        shift
        continue 
        ;;
      -vvv*)
        echo_verbose=true
        shift
        continue
        ;;
      -r|--raw)
        show_raw=true
        shift
        continue
        ;;
      -p|--pretty)
        pretty=true
        shift
        continue
        ;;
      -h|--help)
        jenkins_help 0
    esac
  done

  [[ -z $build_number ]] && echo "need to set a build number" && jenkins_help 1

  JENKINS_REPORT_ENDPOINT=$JENKINS_HOST$JENKINS_JOB"/${build_number}/testReport/api/json"

  # create local artifact repository
  artifact_directory=$TMPDIR/jenkins-script-${buildNumber}
  mkdir -p $artifact_directory
  jenkins_output_file="${artifact_directory}/raw-output"

  response=$(curl -s --user $CREDENTIALS $JENKINS_REPORT_ENDPOINT)

  if ! [ -f $jenkins_output_file ] || [ -z $jenkins_output_file ]; then
    $response > $jenkins_output_file
    if [[ $? != 0 ]]; then 
      echo "check that you're on VPN"
      rm -rf $artifact_directory
      jenkins_usage
      exit 1
    fi
  fi

  if $has_status; then
    if [[ $status == "PASSED" ]] || [[ $status == "FAILED" ]] || [[ $status == "SKIPPED" ]]; then
      jq ".suites[].cases[] | {status: .status, testFile: .className, testName: .name, error: .errorStackTrace} | select(.status == \"${status}\")" $jenkins_output_file 
      exit 0
    fi

      
    if [[ $status == "REGRESSION" ]]; then
      jq ".suites[].cases[] | {status: .status, testFile: .className, testName: .name, error: .errorStackTrace, age: .age} | select(.age == 1)" $jenkins_output_file
      exit 0
    fi
  fi

  if $show_url; then
    echo $JENKINS_REPORT_ENDPOINT
    exit 0
  fi

  if $show_raw; then
    cat $jenkins_output_file
    exit 0
  fi

  if $pretty; then
    jq '.' $jenkins_output_file
    exit 0
  fi

  if $echo_verbose; then
    echo $JENKINS_REPORT_ENDPOINT
    cat $jenkins_output_file
    exit 0
  fi

  cat $jenkins_output_file 
}

