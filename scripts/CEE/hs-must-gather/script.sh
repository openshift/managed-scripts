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

# Sanity check to make sure desired cluster namespace exists
HCP_NS_LIST_LENGTH=$(oc get namespace -l api.openshift.com/id="$CLUSTER_ID" -o json | jq -r '.items | length')
if [ "$HCP_NS_LIST_LENGTH" -ne 1 ]; then
  echo "Number of HCP namespaces matching $CLUSTER_ID must be 1, $HCP_NS_LIST_LENGTH found"
  exit 1
fi

# Fetch the target HCP namespace for the cluster name
HCP_NS=$(oc get namespace -l api.openshift.com/id="$CLUSTER_ID" -o json | jq -r '.items[0].metadata.labels["kubernetes.io/metadata.name"]')

echo "Executing hypershift dump on $HCP_NS for cluster $CLUSTER_ID"
hypershift dump cluster --dump-guest-cluster --namespace "$HCP_NS" --name "$CLUSTER_ID" --artifact-dir "$CLUSTER_ID" --archive-dump=false

echo "Hypershift dump has been saved in $PWD/$CLUSTER_ID"
ls -alh "$PWD"/"$CLUSTER_ID"


# Define the directory containing the dumped files
DUMP_DIR="$PWD/$CLUSTER_ID"
cd "$DUMP_DIR"

# Define the location of the tarball
TARBALL_PATH="${CLUSTER_ID}_dump.tar.gz"

# Check if the tarball already exists. If it does, exit the script.
if [ -f "$TARBALL_PATH" ]; then
  echo "Tarball $TARBALL_PATH already exists. Exiting."
  exit 0
fi

# Remove the sensitive files containing Secrets
find . -name "*.yaml" -print0 | while IFS= read -r -d '' file; do
    if yq e '.kind == "Secret"' "$file" &> /dev/null; then
        rm -f "$file"
    fi
done

# Remove files containing CERTIFICATE data (assuming that it's a field value)
find . -name "*.yaml" -print0 | while IFS= read -r -d '' file; do
    if yq e '.data[] == "CERTIFICATE"' "$file" &> /dev/null; then
        rm -f "$file"
    fi
done

# Compress the remaining files in the dumped folder as a tarball
tar -czvf "${CLUSTER_ID}_dump.tar.gz" ./*

echo "Compressed hypershift dump is saved as ${CLUSTER_ID}_dump.tar.gz"

# End
exit 0
