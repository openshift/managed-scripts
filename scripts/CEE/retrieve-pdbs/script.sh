#!/bin/bash

set -e
set -o nounset
set -o pipefail

# Function to retrieve all namespaces starting with openshift
get_openshift_namespaces() {
    oc get namespaces -o json | jq -r '.items[].metadata.name' | grep '^openshift'
}

# Function to retrieve and display PDBs for a given namespace
get_and_display_pdbs() {
    local namespace="$1"
    echo "---------------------------------"
    echo "PDBs in namespace: $namespace"
    echo ""
    oc get poddisruptionbudget -n "$namespace"
}

# Check if the 'namespace' variable is provided
if [ -z "${namespace:-}" ]; then
    echo "No 'namespace' provided. Retrieving PDBs from all openshift namespaces."
    openshift_namespaces=( $(get_openshift_namespaces) )

    # Loop through each openshift namespace and display PDBs
    for namespace in "${openshift_namespaces[@]}"; do
        echo ""
        get_and_display_pdbs "$namespace"
    done

elif [ "${namespace}" = "--all" ]; then
    echo "Retrieving PDBs from all namespaces in the cluster."
    for namespace in $(oc get namespaces -o jsonpath='{.items[*].metadata.name}'); do
        echo ""
        get_and_display_pdbs "$namespace"
    done

elif [ "${namespace}" = "--restrictive" ]; then
    echo "Checking for restrictive PDBs in all namespaces in the cluster."

    restrictive_found=false

    for namespace in $(oc get namespaces -o jsonpath='{.items[*].metadata.name}'); do
        echo ""
        restrictive_pdbs=$(oc get poddisruptionbudget -n "$namespace" -o json | jq -r '.items[] | select(.spec.maxUnavailable == 0 or .spec.maxUnavailable == "0%") | "\(.metadata.name)\t-->\tmaxUnavailable: \(.spec.maxUnavailable)"')

        if [ -n "${restrictive_pdbs}" ]; then
            echo "---------------------------------"
            echo "Restrictive PDBs found in namespace: $namespace"
            echo "${restrictive_pdbs}"
            restrictive_found=true
        else
            echo "---------------------------------"
            echo "No restrictive PDBs found in namespace: $namespace"
        fi
    done

    if [ "${restrictive_found}" = false ]; then
        echo ""
        echo "---------------------------------"
        echo "No restrictive PDBs found in any namespace."
    fi

else
    echo "Using provided 'namespace' variable: ${namespace}"
    # Split the 'namespace' variable into an array using ',' as the delimiter
    IFS=',' read -ra namespaces <<< "${namespace}"
    NAMESPACE_DEFAULT="${namespaces[@]}"

    # Loop through each provided namespace and display PDBs
    for namespace in "${namespaces[@]}"; do
        echo ""
        get_and_display_pdbs "$namespace"
    done
fi
