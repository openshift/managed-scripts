#!/bin/bash

set -e
set -o nounset
set -o pipefail

## validate input
if [[ -z "$NODE" ]]
then
    echo "Variable node cannot be blank"
    exit 1
fi

# Import sftp_upload library
source /managed-scripts/lib/sftp_upload/lib.sh

# Define expected values
DUMP_DIR="${PWD}"
DATE="$(date -u +"%Y%m%dT%H%M")"
SOSREPORT_FILENAME="sosreport-${NODE}.tar.xz"
SOSREPORT_FILEPATH="${DUMP_DIR}/sosreport-${NODE}.tar.xz"



check_node(){
    echo "Checking if \"${NODE}\" is an existing node..."
    
    if (oc get nodes --no-headers -oname | grep "${NODE}") &> /dev/null; then
       echo "[OK] \"${NODE}\" is a node."
    else
        echo "[Error] \"${NODE}\" is not a node. Exiting script"
        exit 1
    fi
}

generate_sosreport() {
# 1st Debug session - Generate the sosreport and keep it in the host

    echo " ==== Generating SOSREPORT ===="
    oc -n default debug node/"${NODE}" -- sh -c "chroot /host toolbox sos report -k crio.all=on -k crio.logs=on --batch"

    return 0
}

validate_file() {
    echo "==== Check if the sosreport is created inside the node ===="
    oc -n default debug node/"${NODE}" -- bash -c "ls -l /host/var/tmp/*.tar.xz" | tee;

    return 0
}

copy_sosreport() {
# 2nd Debug session - Fetch sosreport .tar.xz file and save inside the container volume.
    oc -n default debug node/"${NODE}" -- bash -c "cat $(find /host/var/tmp/sosreport-"$HOSTNAME"-*.tar.xz | head -1)" > "${DUMP_DIR}"/sosreport-"${NODE}".tar.xz ;

    echo "==== Check if file exists inside container ===="

    ls -la "${DUMP_DIR}"/sosreport-"${NODE}".tar.xz

    echo "======================="

    return 0
}

delete_sosreport_from_node() {
# Deleting any sosreport from the /host/var/tmp inside node

    echo "==== Deleting file from the node ===="
    oc -n default debug node/"${NODE}" -- sh -c "rm /host/var/tmp/sosreport-$HOSTNAME-* && ls -l /host/var/tmp/"

    echo "==== SOSREPORT file should be now not showing in the list ===="

    return 0
}

# Function to upload the tarball to SFTP
upload_sosreport() {
  cd "${DUMP_DIR}"

  # Check if the tarball is in place
  if [ ! -f "${SOSREPORT_FILEPATH}" ]; then
    echo "Sosreport file is not found in ${SOSREPORT_FILEPATH}"
    exit 1
  fi

  sftp_upload "${SOSREPORT_FILEPATH}" "${DATE}-${SOSREPORT_FILENAME}"

  return 0
}

main() {
    check_node
    generate_sosreport
    validate_file
    copy_sosreport
    delete_sosreport_from_node
    upload_sosreport
    
    echo "sosreport process completed successfully"
  }
    
# Execute main function
main
generate_sosreport
validate_file
copy_sosreport
delete_sosreport_from_node
upload_sosreport
