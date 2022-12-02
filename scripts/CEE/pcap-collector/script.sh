#!/bin/bash

set -e

#check the time is less than 900 (15 mins)
if [ "$TIME" -gt 900 ];
then
    echo -e "Time must be less than or equal to 900" >&2
    exit 1
fi

#VARS
NS="openshift-backplane-managed-scripts"
OUTPUTFILE="/tmp/capture-${NODE}.pcap"
PODNAME="pcap-collector-${NODE}"
SECRET_NAME="pcap-collector-creds"
CURRENT_TIMESTAMP=$(date --utc +%Y%m%d_%H%M%SZ)
SFTP_FILENAME="pcap-collector-${CURRENT_TIMESTAMP}.tar.gz"
FTP_HOST="sftp.access.redhat.com"
SFTP_OPTIONS="-o BatchMode=no -o StrictHostKeyChecking=no -b"

ALL_NODES=$(oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
if [[ ! "${ALL_NODES[*]}" =~ ${NODE} ]]
then
    echo -e "There is no node with name ${NODE} in this cluster" >&2
    exit 1
fi

if [ "$(oc -n ${NS} get pod "${PODNAME}" -o jsonpath='{.metadata.name}' 2>/dev/null)" == "$PODNAME" ]
then
    echo -e "There is already a capture pod ${PODNAME} in ${NS} namespace. Please investigate and remove if necessary" >&2
    exit 1
fi

NETWORKTYPE=$(oc get network cluster -o jsonpath='{.spec.networkType}')

case "${NETWORKTYPE}" in
    "OpenShiftSDN") INTERFACE="vxlan_sys_4789"
    ;;
    "OVNKubernetes") INTERFACE="genev_sys_6081"
    ;;
    *) echo "NetworkType is not OpenShiftSDN or OVNKubernetes"
    exit 1
    ;;
esac

# Smoke test to check that the secret exists before creating the pod
oc -n $NS get secret "${SECRET_NAME}" 1>/dev/null

#Create the capture pod
oc create -f -  >/dev/null 2>&1 <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${PODNAME}
  namespace: ${NS}
spec:
  privileged: true
  hostNetwork: true
  restartPolicy: Never
  volumes:
  - name: pcap-upload-volume
    emptyDir: {}
  initContainers:
  - name: pcap-collector
    image: quay.io/app-sre/srep-network-toolbox:latest
    image-pull-policy: Always
    command:
    - '/bin/bash'
    - '-c'
    - |-
      #!/bin/bash
      set -e

      # https://stackoverflow.com/questions/25731643/how-to-schedule-tcpdump-to-run-for-a-specific-period-of-time
      # tcpdump -G just hangs if there is no traffic (so use safer timeout command)
      timeout --preserve-status ${TIME} tcpdump -W 1 -w ${OUTPUTFILE} -i ${INTERFACE} -nn -s0 ${FILTERS} 1> /dev/null

      tar -czf /home/upload/${SFTP_FILENAME} ${OUTPUTFILE}
    volumeMounts:
    - mountPath: /home/upload
      name: pcap-upload-volume
    securityContext:
      capabilities:
        add: ["NET_ADMIN", "NET_RAW"]
      runAsUser: 1001
    nodeSelector:
      kubernetes.io/hostname: ${NODE}
  containers:
  # Adapted from https://github.com/openshift/must-gather-operator/blob/7805956e1ded7741c66711215b51eaf4de775f5c/build/bin/upload
  - name: pcap-uploader
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
      sshpass -e sftp ${SFTP_OPTIONS} - \${username}@${FTP_HOST} << "
          put /home/mustgather/${SFTP_FILENAME} \${REMOTE_FILENAME}
          bye
      "


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
      name: pcap-upload-volume
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
    echo "The pcap collector pod has failed. The logs are:"
    # Do not error if uploader pod is still in initialising state
    oc -n $NS logs "${PODNAME}" -c pcap-collector || true
    oc -n $NS logs "${PODNAME}" -c pcap-uploader || true
    oc -n $NS delete secret "${SECRET_NAME}" >/dev/null 2>&1
    oc -n $NS delete pod "${PODNAME}" >/dev/null 2>&1
    exit 1
  fi
  sleep 30
done

oc -n $NS delete secret "${SECRET_NAME}" >/dev/null 2>&1
oc -n $NS logs "${PODNAME}" -c pcap-collector
oc -n $NS logs "${PODNAME}" -c pcap-uploader
oc -n $NS delete pod "${PODNAME}"  >/dev/null 2>&1

echo "PCAP file successfully uploaded to case!"
