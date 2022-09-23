#!/bin/bash
#
# Description: Lists master machines of a cluster.

# Fail fast and be aware of exit codes
set -euo pipefail

# Global variables
readonly NAMESPACE="openshift-machine-api"
readonly LOG_INFO="INFO:"
readonly LOG_ERROR="ERROR:"

# OCP environment validation.
validate_environment() {
 if [[ "$(oc whoami 2>/dev/null | wc -l | xargs echo)" == "0" ]]; then
   echo "$LOG_ERROR You must be logged into an OSD/ROSA cluster to run this script."
   return 1
 fi
}

# Input validation.
# Checks if the given input is not empty.
validate_input() {
 echo "$LOG_INFO validating input..."
 if [[ -z "$NAMESPACE" ]]; then
   echo "$LOG_ERROR Namespace cannot be blank"
   return 1
 fi
}

# Lists all master machines of a cluster.
get_master_machines() {
 local label="machine.openshift.io/cluster-api-machine-type=master"
 master_machines=$(oc get machines -n $NAMESPACE -l $label)
 echo "$LOG_INFO $master_machines"
}

main() {
 validate_environment
 validate_input
 get_master_machines
 exit 0
}

main "$@"