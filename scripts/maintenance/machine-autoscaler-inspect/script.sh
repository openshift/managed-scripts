#!/bin/bash

set -e
set -o nounset
set -o pipefail

#VARS
NAMESPACE="openshift-machine-api"

echo "Fetching machine autoscaler resources in namespace '$NAMESPACE'..."
# Fetch machine autoscaler names
MACHINE_AUTOSCALERS=$(oc get machineautoscaler -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
if [ -z "$MACHINE_AUTOSCALERS" ]; then
  echo "No machine autoscaler resources found in namespace '$NAMESPACE'."
  exit 1
fi

echo "Collecting machine autoscaler resources..."
for AUTOSCALER in $MACHINE_AUTOSCALERS; do
  # Print the current machine autoscaler YAML 
  if ! oc get machineautoscaler "$AUTOSCALER" -n "$NAMESPACE" -o yaml; then 
    echo "Failed to fetch details for machine autoscaler '$AUTOSCALER'. Skipping..."
  fi
done
