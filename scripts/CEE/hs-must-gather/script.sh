#!/bin/bash

set -e
set -o nounset
set -o pipefail

# Define expected values 
HS_BINARY_PATH="/usr/local/bin/hypershift"

# Check if hypershift binary is in place 
if [ ! -f "$HS_BINARY_PATH" ]; then
  echo "HyperShift binary not found in $HS_BINARY_PATH path" 
  exit 1
fi

# Sanity check for multiple namespaces matching label
HCP_NS_LIST_LENGTH=$(oc get namespace -l api.openshift.com/id="$CLUSTER_ID" -o json | jq -r '.items | length')
if [ "$HCP_NS_LIST_LENGTH" -ne 1 ]; then
  echo "Number of HCP namespaces matching $CLUSTER_ID must be 1, $HCP_NS_LIST_LENGTH found"
  exit 1
fi

# Fetch the target HCP namespace for the cluster name
HCP_NS=$(oc get namespace -l api.openshift.com/id="$CLUSTER_ID" -o json | jq -r '.items[0].metadata.labels["kubernetes.io/metadata.name"]')

echo "Executing hypershift dump on $HCP_NS for cluster $CLUSTER_ID"
hypershift dump cluster --dump-guest-cluster --namespace "$HCP_NS" --name "$CLUSTER_ID" --artifact-dir "$CLUSTER_ID"

echo "Hypershift dump has been saved in $PWD/$CLUSTER_ID"
ls -alh "$PWD"/"$CLUSTER_ID"

# End
exit 0
