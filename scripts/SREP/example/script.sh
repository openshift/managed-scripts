#!/bin/bash

# Source the logging system
source ../../LIBRARY/liblog.sh

# Log a message at the INFO level
log_info "Getting pods in openshift-monitoring namespace"

# Get pods in the openshift-monitoring namespace
oc -n openshift-monitoring get po

# Log a message at the DEBUG level, with a variable interpolated in the message
var1="foo"
log_debug "The value of var1 is ${var1}"

log_info "Script executed successfully"
exit 0


