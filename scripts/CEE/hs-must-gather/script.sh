#!/bin/bash

set -e

#VARS
NS="openshift-backplane-managed-scripts"
PODNAME="hs-mg"
SECRET_NAME="hs-mg-creds"
CURRENT_TIMESTAMP=$(date --utc +%Y%m%d_%H%M%SZ)
SFTP_FILENAME="hs-mg-${CURRENT_TIMESTAMP}.tar.gz"
FTP_HOST="sftp.access.redhat.com"
SFTP_OPTIONS="-o BatchMode=no -o StrictHostKeyChecking=no -b"


if [ "$(oc -n ${NS} get pod "${PODNAME}" -o jsonpath='{.metadata.name}' 2>/dev/null)" == "$PODNAME" ]
then
    echo -e "There is already a must-gather pod ${PODNAME} in ${NS} namespace. Please investigate and remove if necessary" >&2
    exit 1
fi


# Smoke test to check that the secret exists before creating the pod
oc -n $NS get secret "${SECRET_NAME}" 1>/dev/null

#Create the capture pod
# shellcheck disable=SC1039
oc create -f -  >/dev/null 2>&1 <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${PODNAME}
  namespace: ${NS}
spec:
  privileged: true
  restartPolicy: Never
  volumes:
  - name: mg-upload-volume
    emptyDir: {}
  initContainers:
  - name: mg-collector
    image: quay.io/app-sre/managed-scripts:c6a654a
    image-pull-policy: Always
    command:
    - '/bin/bash'
    - '-c'
    - |-
      #!/bin/bash

      set -e
      set -o nounset
      set -o pipefail

      cd /home/upload
      # Define expected values
      HS_BINARY_PATH="/usr/local/bin/hypershift"

      # Check if hypershift binary is in place
      if [ ! -f "\${HS_BINARY_PATH}" ]; then
        echo "HyperShift binary not found in \${HS_BINARY_PATH} path"
        exit 1
      fi

      # Sanity check to make sure desired cluster namespace exists
      HCP_NS_LIST_LENGTH=$(oc get namespace -l api.openshift.com/id=${CLUSTER_ID} -o json | jq -r '.items | length')
      if [ "\${HCP_NS_LIST_LENGTH}" -ne 1 ]; then
        echo "Number of HCP namespaces matching ${CLUSTER_ID} must be 1, \${HCP_NS_LIST_LENGTH} found"
        exit 1
      fi

      # Fetch the target HCP namespace for the cluster name
      HCP_NS=$(oc get namespace -l api.openshift.com/id="${CLUSTER_ID}" -o json | jq -r '.items[0].metadata.labels["kubernetes.io/metadata.name"]')

      echo "Executing hypershift dump on \${HCP_NS} for cluster $CLUSTER_ID"
      hypershift dump cluster --dump-guest-cluster --namespace "\${HCP_NS}" --name "$CLUSTER_ID" --artifact-dir "$CLUSTER_ID" --archive-dump=false

      echo "Hypershift dump has been saved in \${PWD}/${CLUSTER_ID}"
      ls -alh \${PWD}/${CLUSTER_ID}
      tar -czf /home/upload/${SFTP_FILENAME} \${PWD}/${CLUSTER_ID}
      # End
      exit 0

    volumeMounts:
    - mountPath: /home/upload
      name: mg-upload-volume
    securityContext:
      runAsUser: 1001
  containers:
  # Adapted from https://github.com/openshift/must-gather-operator/blob/7805956e1ded7741c66711215b51eaf4de775f5c/build/bin/upload
  - name: mg-uploader
    image: quay.io/app-sre/must-gather-operator
    image-pull-policy: Always
    command:
    - '/bin/bash'
    - '-c'
    - |-
      #!/bin/bash
      set -e
      if [ -z "\${caseid}" ] || [ -z "\${username}" ] || [ -z "\${SSHPASS}" ];
      then
        echo "Error: Required Parameters have not been provided. Make sure the ${SECRET_NAME} secret exists in namespace openshift-backplane-managed-scripts. Exiting..."
        exit 1
      fi

      echo "Uploading '${SFTP_FILENAME}' to Red Hat Customer SFTP Server for case \${caseid}"

      REMOTE_FILENAME=\${caseid}_${SFTP_FILENAME}

      if [[ "\${internal_user}" == true ]]; then
        # internal users must upload to a different path on the sftp
        REMOTE_FILENAME="\${username}/\${REMOTE_FILENAME}"
      fi

      # upload file and detect any errors
      echo "Uploading ${SFTP_FILENAME}..."
      sshpass -e sftp ${SFTP_OPTIONS} - \${username}@${FTP_HOST} << EOF
          put /home/mustgather/${SFTP_FILENAME} \${REMOTE_FILENAME}
          bye
      EOF

      if [[ \$? == 0 ]];
      then
        echo "Successfully uploaded '${SFTP_FILENAME}' to Red Hat SFTP Server for case \${caseid}!"
      else
        echo "Error: Upload to Red Hat Customer SFTP Server failed. Make sure that you are not using the same SFTP token more than once."
        exit 1
      fi
    volumeMounts:
    # This directory needs to be used, as it has the correct user/group permissions set up in the must gather container.
    # See https://github.com/openshift/must-gather-operator/blob/7805956e1ded7741c66711215b51eaf4de775f5c/build/bin/user_setup
    - mountPath: /home/mustgather
      name: mg-upload-volume
    env:
    - name: username
      valueFrom:
        secretKeyRef:
          name: ${SECRET_NAME}
          key: username
    - name: SSHPASS
      valueFrom:
        secretKeyRef:
          name: ${SECRET_NAME}
          key: password
    - name: caseid
      valueFrom:
        secretKeyRef:
          name: ${SECRET_NAME}
          key: caseid
    - name: internal_user
      valueFrom:
        secretKeyRef:
          name: ${SECRET_NAME}
          key: internal
EOF

while [ "$(oc -n ${NS} get pod "${PODNAME}" -o jsonpath='{.status.phase}' 2>/dev/null)" != "Succeeded" ];
do
  if [ "$(oc -n ${NS} get pod "${PODNAME}" -o jsonpath='{.status.phase}' 2>/dev/null)" == "Failed" ];
  then
    echo "The mg collector pod has failed. The logs are:"
    # Do not error if uploader pod is still in initialising state
    oc -n $NS logs "${PODNAME}" -c mg-collector || true
    oc -n $NS logs "${PODNAME}" -c mg-uploader || true
    oc -n $NS delete secret "${SECRET_NAME}" >/dev/null 2>&1
    oc -n $NS delete pod "${PODNAME}" >/dev/null 2>&1
    exit 1
  fi
  sleep 30
done

oc -n $NS delete secret "${SECRET_NAME}" >/dev/null 2>&1
oc -n $NS logs "${PODNAME}" -c mg-collector
oc -n $NS logs "${PODNAME}" -c mg-uploader
oc -n $NS delete pod "${PODNAME}"  >/dev/null 2>&1

echo "Must gather file successfully uploaded to case!"
