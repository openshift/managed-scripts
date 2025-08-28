#!/bin/bash

set -e
set -o nounset
set -o pipefail

# shellcheck source=/dev/null
source /managed-scripts/lib/sftp_upload/lib.sh

# Define expected values
TODAY=$(date -u +%Y%m%d%H%M%S)
DUMP_DIR="/tmp/${CLUSTER_ID}_manifests_${TODAY}"
TARBALL_NAME="${CLUSTER_ID}_manifests_${TODAY}.tar.gz"
TARBALL_PATH="${DUMP_DIR}/${TARBALL_NAME}"

# Create dump dir
mkdir -p "${DUMP_DIR}"

# Function to collect ACM HyperShift must-gather - manifests only
collect_manifests() {

  # Check if required CLIs are present
  if ! command -v oc >/dev/null 2>&1; then
    echo "oc binary not found in PATH"
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq binary not found in PATH"
    exit 1
  fi
  if ! command -v yq >/dev/null 2>&1; then
    echo "yq binary not found in PATH"
    exit 1
  fi

  # Sanity check to make sure desired cluster namespace exists
  hcp_ns_list_length=$(oc get namespace -l api.openshift.com/id="${CLUSTER_ID}" -o json | jq -r '.items | length')
  if [ "${hcp_ns_list_length}" -ne 1 ]; then
    echo "Number of HCP namespaces matching ${CLUSTER_ID} must be 1, ${hcp_ns_list_length} found"
    exit 1
  fi

  # Fetch the target HCP namespace for the cluster name
  hc_namespace=$(oc get namespace -l api.openshift.com/id="${CLUSTER_ID}" -o json | jq -r '.items[0].metadata.name')

  # Fetch the HostedCluster name
  hc_name=$(oc get HostedCluster.hypershift.openshift.io -l api.openshift.com/id="${CLUSTER_ID}" -n "${hc_namespace}" -o json | jq -r '.items[0].metadata.name')

  
  # TODO(ACM-16170): replace this with an official ACM release image once it's available
  local acm_hypershift_image="registry.redhat.io/rhacm2/acm-must-gather-rhel9:v2.13"

  # Create gather script command
  local gather_script="/usr/bin/gather hosted-cluster-namespace=${hc_namespace} hosted-cluster-name=${hc_name}"
  
  echo "Collecting ACM HyperShift must-gather(manifests only) for cluster ${hc_name} in namespace ${hc_namespace}"
  
  # Execute must-gather
  if ! oc adm must-gather --dest-dir="${DUMP_DIR}" --image="${acm_hypershift_image}" -- "${gather_script}"; then
    echo "failed to gather ACM HyperShift manifests data: oc adm must-gather failed"
    return 1
  fi
  
  echo "ACM HyperShift must-gather(manifests only) completed successfully"
  ls -alh "${DUMP_DIR}"
  return 0
}

# Function to remove files with Secrets and CERTIFICATE data
remove_sensitive_files() {
  cd "${DUMP_DIR}"

  find . -type f -name "*.yaml" -print0 | while IFS= read -r -d '' file; do
    if [ "$(yq e '.kind == "Secret"' "${file}" 2> /dev/null)" = "true" ]; then
      echo "Removing ${file} because it contains a Secret"
      rm -f "${file}"
    elif [ "$(yq e '.kind == "SecretList"' "${file}" 2> /dev/null)" = "true" ]; then
      echo "Removing ${file} because it contains a SecretList"
      rm -f "${file}"
    elif [ "$(yq e 'select(.data[] | contains("CERTIFICATE")) | [.] | length > 0' "${file}" 2> /dev/null)" = "true" ]; then
      echo "Removing ${file} because it contains CERTIFICATE data"
      rm -f "${file}"
    elif [ "$(yq e 'select(.items[].data[] | contains("CERTIFICATE")) | [.] | length > 0' "${file}" 2> /dev/null)" = "true" ]; then
      echo "Removing ${file} because it contains CERTIFICATE data"
      rm -f "${file}"
    fi
  done

  return 0
}

# Function to compress the dump into a tarball
create_tarball() {
  cd "${DUMP_DIR}"

  if [ -f "${TARBALL_PATH}" ]; then
    echo "Tarball ${TARBALL_PATH} already exists. Exiting."
    exit 0
  fi

  # Compress the dump directory
  tar -czvf "${TARBALL_PATH}" ./*

  echo "Compressed manifests archive is saved as ${TARBALL_PATH}"

  return 0
}

# Function to upload the tarball to SFTP
upload_tarball() {
  cd "${DUMP_DIR}"

  # Check if the tarball is in place
  if [ ! -f "${TARBALL_PATH}" ]; then
    echo "Tarball is not found in ${TARBALL_PATH}"
    exit 1
  fi

  sftp_upload "${TARBALL_PATH}" "${TARBALL_NAME}"

  return 0
}

# Calling functions to gather manifests, remove sensitive data and upload.
collect_manifests
remove_sensitive_files
create_tarball
upload_tarball

# End
exit 0 