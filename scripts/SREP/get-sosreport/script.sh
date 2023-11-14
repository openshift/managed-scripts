#!/bin/bash
#set -e
#set -o nounset
#set -o pipefail

# Import sftp_upload library
source /managed-scripts/lib/sftp_upload/lib.sh

# Define expected values
DUMP_DIR="${PWD}"
DATE="$(date +"%Y%m%d%p")"
NODE="ip-10-0-178-83.eu-west-1.compute.internal"
SOSREPORT_FILENAME="${NODE}-sosreport.tar.xz"
SOSREPORT_FILEPATH="${DUMP_DIR}/${NODE}-sosreport.tar.xz"

# /host/var/tmp/sosreport-ip-10-0-178-83-2023-11-14-dscgket.tar.xz
# Mostrar PWD -> pwd == /root
echo $(pwd)

generate_sosreport() {
# 1st Debug session - Generate the sosreport and keep it in the host

    echo " ==== Generating SOSREPORT ===="
    oc -n default debug node/"${NODE}" -- sh -c 'chroot /host toolbox sos report -k crio.all=on -k crio.logs=on --batch'

    return 0
}

validate_file() {
    echo "==== Check if the sosreport is created inside the node ===="
    oc -n default debug node/"${NODE}" -- bash -c 'ls -l /host/var/tmp/*.tar.xz' | tee;

    return 0
}

copy_sosreport() {
# 2nd Debug session - Fetch sosreport .tar.xz file and save inside the container volume.
    oc -n default debug node/"${NODE}" -- bash -c 'cat $(ls -tA /host/var/tmp/*.tar.xz | head -1)' > ${DUMP_DIR}/${NODE}-sosreport.tar.xz ;

    echo "==== Check if file exists inside container ===="

    ls -la ${DUMP_DIR}/${NODE}-sosreport.tar.xz

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

generate_sosreport
validate_file
copy_sosreport
upload_sosreport
