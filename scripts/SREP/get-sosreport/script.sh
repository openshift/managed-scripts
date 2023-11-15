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
    if ! oc -n default debug node/"${NODE}" -- bash -c "ls -l /host/var/tmp/*.tar.xz" | tee;
        then printf "========\n [Error] Sosreport file not found in node directory /host/var/tmp dir \n========"
        exit 1
        else printf "========\n [Success] Sosreport file generated\n========\n"
    fi
}

copy_sosreport() {
# 2nd Debug session - Fetch sosreport .tar.xz file and save in the container volume.
    oc -n default debug node/"${NODE}" -- bash -c 'cat $(ls /host/var/tmp/sosreport-"$(echo "${NODE}" |cut -d '.' -f 1)"-*.tar.xz |head -1)' > "${DUMP_DIR}"/sosreport-"${NODE}".tar.xz ;

    if ! ls -la "${DUMP_DIR}"/sosreport-"${NODE}"-*.tar.xz;
        then printf "========\n [Error] Sosreport file not found in backplane container\n========"
        exit 1
        else printf "========\n [Success] Sosreport copied to backplane container\n========"
    fi

    ls -la "${DUMP_DIR}"
}

delete_sosreport_from_node() {
# Deleting any sosreport from the /host/var/tmp inside node

    printf "\n========\n Deleting file from the node \n========"
    oc -n default debug node/"${NODE}" -- sh -c "rm /host/var/tmp/sosreport-"$(echo ${NODE} |cut -d '.' -f 1)"-*.tar.*"

    if oc -n default debug node/"${NODE}" -- bash -c "ls -l /host/var/tmp/sosreport-"$(echo ${NODE} |cut -d '.' -f 1)"-*.tar.*" | tee;
        then echo "Error: sosreport file not deleted - Please check with SRE for manual removal in directory /host/var/tmp/"
        exit 1
        else printf "========\n [Success] Sosreport file deleted from the node \n========"
    fi
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

main () {
#check_node
#generate_sosreport
validate_file
copy_sosreport
#delete_sosreport_from_node
#upload_sosreport
}

main