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


# Define the variable DUMP_DIR in global
DUMP_DIR="$PWD/$CLUSTER_ID"

# Function to remove files with Secrets and CERTIFICATE data
remove_sensitive_files() {
  cd "$DUMP_DIR"

  find . -type f -name "*.yaml" -print0 | while IFS= read -r -d '' file; do
    if yq e '.kind == "Secret"' "$file" &> /dev/null; then
        echo "Removing $file because it contains a Secret"
        rm -f "$file"
    elif yq e '.data[] == "CERTIFICATE"' "$file" &> /dev/null; then
        echo "Removing $file because it contains CERTIFICATE data"
        rm -f "$file"
    fi
  done
}

# Function to compress the dump into a tarball
create_tarball() {
  cd "$DUMP_DIR"
  TARBALL_PATH="${DUMP_DIR}/${CLUSTER_ID}_dump.tar.gz"

  if [ -f "$TARBALL_PATH" ]; then
    echo "Tarball $TARBALL_PATH already exists. Exiting."
    exit 0
  fi

  # Compress the dump directory
  tar -czvf "$TARBALL_PATH" ./*

  echo "Compressed hypershift dump is saved as $TARBALL_PATH"
}

# Calling functions to remove the sensitive files and make a compress tarball
remove_sensitive_files
create_tarball

# End
exit 0
