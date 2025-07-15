#!/bin/bash
#
# Command: describe-nodes
# Description: Describes the nodes in a cluster by calling `oc describe nodes`
#              This is useful to be run as a backplane script where more more authorisation can be provided when compared to the standard backplane cli access. 

# Exit on error
set -e
# Treat unset variables as error
set -u
# Print expanded commands with arguments before executing them
# set -x
# Set the return value in a set of pipes to the rightmost failed command
set -o pipefail

# Enable debugging if the DEBUG envvar is set as true
if [ "${DEBUG:-false}" = "true" ]
then
    set -x
fi

# Add argument to the nodes variable
function add2nodes() {
  nodes="${nodes}${1}"
}

# List nodes that match a specific selector past in as $1
function list-selector() {
    oc get nodes -l "${1}" --no-headers -o custom-columns=":metadata.name" | tr "\n" ","
}

nodes=""

# Parse command line arguments
if [ -n "${NODES-}" ]
then
    add2nodes "${NODES}"
elif [ -n "${SELECTOR-}" ]
then
    add2nodes "$(list-selector "${SELECTOR}")"
elif [ "${ALL:-false}" = "true" ]
then
    add2nodes "$(oc get nodes --no-headers -o custom-columns=":metadata.name" | tr "\n" ",")"
else
    if [ "${MASTER:-false}" = "true" ]
    then
      add2nodes "$(list-selector "node-role.kubernetes.io/master")"
    fi
    if [ "${INFRA:-false}" = "true" ]
    then
      add2nodes "$(list-selector "node-role.kubernetes.io=infra")"
    fi
    if [ "${WORKER:-false}" = "true" ]
    then
      add2nodes "$(list-selector "node-role.kubernetes.io!=infra,node-role.kubernetes.io/worker")"
    fi
fi

# If the nodes variable is empty, it means the no arguments were supplied on the command line
# Or the selector(s) did not pick any nodes.  This is an error
if [ -z "${nodes}" ]
then
  echo "No nodes selected"
  exit 1
fi

IFS=',' read -r -a nodearray <<< "${nodes}"
oc describe nodes "${nodearray[@]}"
exit 0
