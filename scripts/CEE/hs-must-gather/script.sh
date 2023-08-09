#!/bin/bash

set -e
set -o nounset
set -o pipefail

# Define expected values 
HS_BINARY_PATH="/usr/local/bin/hypershift"

# Check if hypershift binary is in place 
if [ ! -f "$HS_BINARY_PATH" ]; then
  echo "Hypershift binary not available in $HS_BINARY_PATH path" 
  exit 1
fi

# Sanity check for multiple namespaces matching label
HCP_NS_LIST_LENGTH=$(oc get namespace -l api.openshift.com/name="$CLUSTER_NAME" -o json | jq -r '.items | length')
if [ "$HCP_NS_LIST_LENGTH" -ne 1 ]; then
  echo "Number of HCP namespaces matching $CLUSTER_NAME must be 1, $HCP_NS_LIST_LENGTH found"
  exit 1
fi

# Fetch the target HCP namespace for the cluster name
HCP_NS=$(oc get namespace -l api.openshift.com/name="$CLUSTER_NAME" -o json | jq -r '.items[0].metadata.labels["kubernetes.io/metadata.name"]')

echo "Executing hypershift dump on $HCP_NS for cluster $CLUSTER_NAME"
hypershift dump cluster --dump-guest-cluster --namespace "$HCP_NS" --name "$CLUSTER_NAME" --artifact-dir "$CLUSTER_NAME"

echo "Hypershift dump has been saved in $PWD/$CLUSTER_NAME"
ls -alh "$PWD"/"$CLUSTER_NAME"

# End
exit 0
