#!/bin/bash
###############################################################################
#                                                                             #
#      Check Managed Scripts metadata.yaml files against the JSON Schema      #
#                                                                             #
###############################################################################
#
# release: v2.0
# description: Script responsible for listing the metadata.yaml files in the
#              managed scripts directory and for running the validation 
#              against the Json Schema.
# team: SREP
# author: Fabio Aldana
# email: faldana@redhat.com
#

#set -ex

# define variables
CONTAINER_ENGINE=$(which docker 2>/dev/null || which podman)
CONTAINER_PATH=/json

# change to the managed-scripts directory on your repository
cd $(dirname $0)/..

# function to present the help
usage() {
  cat <<EOF >&2
  Usage: $0 <options> [script1] [scriptN]

    Check Managed Scripts metadata.yaml files against the JSON Schema.

    The script can be run with no arguments, which runs against all files found 
    in the managed-scripts directory, or it can be specified the scripts to be
    validated.

    Options:

      -h, --help        Shows the script usage.
EOF
}

# function which validates the list of scripts and adds the container path to each file found
yamlList() {

  if [ ! -z "$listYamlFiles" ]; then
    for i in $listYamlFiles
    do
      yamlFiles+="$CONTAINER_PATH$i "
    done
    # calls check_validation function to run the validation on the scripts
    check_validation
  else
    echo "error: no file was found."
    exit 1
  fi

}

# function to validate the Yaml files
check_validation() {

#  echo "validating the jsonschema for $yamlFiles"
  echo "CI-DEBUG"

  $CONTAINER_ENGINE run --rm -v $(pwd):$CONTAINER_PATH quay.io/app-sre/managed-scripts:latest whoami
  $CONTAINER_ENGINE run --rm -v $(pwd):$CONTAINER_PATH quay.io/app-sre/managed-scripts:latest ls -ld /
  $CONTAINER_ENGINE run --rm -v $(pwd):$CONTAINER_PATH quay.io/app-sre/managed-scripts:latest ls -ld /json
  $CONTAINER_ENGINE run --rm -v $(pwd):$CONTAINER_PATH quay.io/app-sre/managed-scripts:latest ls -l /json/
  $CONTAINER_ENGINE run --rm -v $(pwd):$CONTAINER_PATH quay.io/app-sre/managed-scripts:latest ls -l /json/scripts
}

# function that list all files in the manage-scripts directory
all() {

  # list all yaml files
  listYamlFiles="$(find . -name 'metadata.yaml' | cut -c 2- ) "

  # calls yamList function to prepare the scripts to be validated
  yamlList

}

# function that list the scripts passed as arguments
partial() {

  # list the number of arguments
  for ((i = 1; i <= $#; i++ ));
  do
    # list the yaml files based on the arguments
    listYamlFiles+="$(find ./scripts/*/${!i} -name 'metadata.yaml' | cut -c 2- ) "
  done

  # calls yamList function to prepare the scripts to be validated
  yamlList

}

# get the options
while getopts ":h" option; do
   case $option in
      h) # display Help
        usage
        exit;;
      *) 
        echo "error: invalid option."
        echo
        usage
        exit 1;;
   esac
done

# if no arguments, it calls all function, or with arguments, calls partial function parsing the arguments
if [ -z "$1" ]; then
  all
else
  partial $@
fi
