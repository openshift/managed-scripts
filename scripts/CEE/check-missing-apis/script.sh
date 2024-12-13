#!/bin/bash
set -euo pipefail

echo "Checking for missing OpenShift APIServices..."

# Capture the output of `oc get apiservice` into a variable in JSON format
api_services=$(oc get apiservice -o json)

# Use jq to iterate over each API service and check their status
jq -c '.items[] | {name: .metadata.name, status: (.status.conditions[]? | select(.type == "Available").status // "Unknown")}' <<< "$api_services" |
while IFS= read -r line; do
    # Extract the API name and status
    api=$(echo "$line" | jq -r '.name')
    status=$(echo "$line" | jq -r '.status')

    # Check if the STATUS is not True
    if [[ "$status" != "True" ]]; then
        echo "API Service not available: $api (STATUS: $status)"
    fi
done

echo "Checking for missing OpenShift APIServices finished."
