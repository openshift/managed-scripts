#!/bin/bash

set -e
set -o nounset
set -o pipefail

# Function to retrieve all namespaces starting with openshift
get_openshift_namespaces() {
    oc get namespaces -o json | jq -r '.items[].metadata.name' | grep '^openshift'
}

# Function to retrieve and display events for a given namespace sorted by timestamp
get_and_display_events() {
    local namespace="$1"
    echo "---------------------------------"
    echo "Events in namespace: $namespace (sorted by timestamp)"
    echo ""
    oc get events -n "$namespace" --sort-by=.metadata.creationTimestamp
}

# Check if the 'namespace' variable is provided
if [ -z "${namespace:-}" ]; then
    echo "No 'namespace' provided. Retrieving events from all openshift namespaces."
    IFS=' ' read -r -a openshift_namespaces <<< "${get_openshift_namespaces}"

    # Loop through each openshift namespace and display events
    for namespace in "${openshift_namespaces[@]}"; do
        echo ""
        get_and_display_events "$namespace"
    done

elif [ "${namespace}" = "--all" ]; then
    echo "Retrieving events from all namespaces in the cluster."
    for namespace in $(oc get namespaces -o jsonpath='{.items[*].metadata.name}'); do
        echo ""
        get_and_display_events "$namespace"
    done

else
    echo "Using provided 'namespace': ${namespace}"
    # Split the 'namespace' variable into an array using ',' as the delimiter
    IFS=',' read -ra namespaces <<< "${namespace}"
    # To avoid the SC2034
    export NAMESPACE_DEFAULT=""
    NAMESPACE_DEFAULT="${namespaces[*]}"

    # Loop through each provided namespace and display events
    for namespace in "${namespaces[@]}"; do
        echo ""
        get_and_display_events "$namespace"
    done
fi
