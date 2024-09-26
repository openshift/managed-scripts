#!/bin/bash

set -e
set -o nounset
set -o pipefail

# shellcheck source=/dev/null
source /managed-scripts/lib/sftp_upload/lib.sh

# Define expected values
HS_BINARY_PATH="/usr/local/bin/hypershift"
DUMP_DIR="/tmp/${CLUSTER_ID}"
TODAY=$(date -u +%Y%m%d)
TARBALL_NAME="${TODAY}_${CLUSTER_ID}_dump.tar.gz"
TARBALL_PATH="${DUMP_DIR}/${TARBALL_NAME}"
HC_DUMP_DIR=""
CP_DUMP_DIR=""

# Function to run a hypershift dump on the HCP namespace
collect_must_gather() {
  # Check if hypershift binary is in place
  if [ ! -f "${HS_BINARY_PATH}" ]; then
    echo "HyperShift binary not found in ${HS_BINARY_PATH} path"
    exit 1
  fi

  # Sanity check to make sure desired cluster namespace exists
  hcp_ns_list_length=$(oc get namespace -l api.openshift.com/id="${CLUSTER_ID}" -o json | jq -r '.items | length')
  if [ "${hcp_ns_list_length}" -ne 1 ]; then
    echo "Number of HCP namespaces matching ${CLUSTER_ID} must be 1, ${hcp_ns_list_length} found"
    exit 1
  fi

  # Fetch the target HCP namespace for the cluster name
  hcp_ns=$(oc get namespace -l api.openshift.com/id="${CLUSTER_ID}" -o json | jq -r '.items[0].metadata.labels["kubernetes.io/metadata.name"]')

  # Fetch the HostedCluster name
  hc_name=$(oc get HostedCluster.hypershift.openshift.io -l api.openshift.com/id="${CLUSTER_ID}" -n "${hcp_ns}" -o json | jq -r '.items[0].metadata.name')

  HC_DUMP_DIR="hostedcluster-${hc_name}"
  CP_DUMP_DIR="controlplane-${hc_name}"

  if [ "${DUMP_GUEST_CLUSTER}" = "true" ]; then
    echo "Executing hypershift dump on ${hcp_ns} for cluster ${hc_name}, including guest cluster"
    hypershift dump cluster --dump-guest-cluster --namespace "${hcp_ns}" --name "${hc_name}" --artifact-dir "${DUMP_DIR}" --archive-dump=false
  else
    echo "Executing hypershift dump on ${hcp_ns} for cluster ${hc_name}, excluding guest cluster"
    hypershift dump cluster --namespace "${hcp_ns}" --name "${hc_name}" --artifact-dir "${DUMP_DIR}" --archive-dump=false
  fi

  echo "Hypershift dump has been saved in ${DUMP_DIR}"
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

# HyperShift dump nests the hosted cluster log inside the HCP logs
# This is hard to use so we arrange them here
arrange_files() {
  cd "${DUMP_DIR}"

  echo "Arranging gathered logs"

  # create directory to store control plane logs 
  mkdir "${CP_DUMP_DIR}"

  # move all files to control plane logs directory
  echo "Moving control plane logs into ${CP_DUMP_DIR}"
  find . -maxdepth 1 -mindepth 1 ! -name "${CP_DUMP_DIR}" -exec mv {} -t "${CP_DUMP_DIR}" \;

  # move the hostedcluster logs out from the control plane logs dirctory
  if [ "${DUMP_GUEST_CLUSTER}" = "true" ]; then 
    echo "Moving hosted cluster logs into ${HC_DUMP_DIR}"
    mv "${CP_DUMP_DIR}/${HC_DUMP_DIR}" "${DUMP_DIR}"
  fi

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

  echo "Compressed hypershift dump is saved as ${TARBALL_PATH}"

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

# Calling functions to gather must-gather, remove sensitive data and upload.
collect_must_gather
remove_sensitive_files
arrange_files
create_tarball
upload_tarball

# End
exit 0
