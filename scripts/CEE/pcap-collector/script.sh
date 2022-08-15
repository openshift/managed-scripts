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

ALL_NODES=$(oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
if [[ ! "${ALL_NODES[*]}" =~ ${NODE} ]]
then
    echo -e "There is no node with name $NODE in this cluster" >&2
    exit 1
fi

if [ "$(oc -n ${NS} get pod "${PODNAME}" -o jsonpath='{.metadata.name}' 2>/dev/null)" == "$PODNAME" ]
then
    echo -e "There is already a capture pod $PODNAME in $NS namespace. Please investigate and remove if necessary" >&2
    exit 1
fi

NETWORKTYPE=$(oc get network cluster -o jsonpath='{.spec.networkType}')

case "$NETWORKTYPE" in
    "OpenShiftSDN") INTERFACE="vxlan_sys_4789"
    ;;
    "OVNKubernetes") INTERFACE="genev_sys_6081"
    ;;
    *) echo "NetworkType is not OpenShiftSDN or OVNKubernetes"
    exit 1
    ;;
esac


#Create the capture pod
oc create -f - >/dev/null 2>&1 <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${PODNAME}
  namespace: ${NS}
spec:
  privileged: true
  hostNetwork: true
  restartPolicy: Never
  containers:
  - name: pcap-collector
    image: quay.io/app-sre/srep-network-toolbox:latest
    image-pull-policy: Always
    command:
    - '/bin/bash'
    - '-c'
    - |-
      #!/bin/bash

      set -e

      tcpdump -G ${TIME} -W 1 -w ${OUTPUTFILE} -i ${INTERFACE} -nn -s0 > /dev/null 2>&1
      gzip ${OUTPUTFILE} --stdout
    securityContext:
      capabilities:
        add: ["NET_ADMIN", "NET_RAW"]
      runAsUser: 1001
    nodeSelector:
      kubernetes.io/hostname: ${NODE}
EOF

while [ "$(oc -n ${NS} get pod "${PODNAME}" -o jsonpath='{.status.phase}' 2>/dev/null)" != "Succeeded" ];
do
  if [ "$(oc -n ${NS} get pod "${PODNAME}" -o jsonpath='{.status.phase}' 2>/dev/null)" == "Failed" ];
  then
    echo "The pcap collector pod has failed. The logs are:"
    oc -n $NS logs "$PODNAME"
    oc -n $NS delete pod "$PODNAME"
    exit 1
  fi
  sleep 30
done

oc -n $NS logs "$PODNAME" > "$OUTPUTFILE"
oc -n $NS delete pod "$PODNAME" >/dev/null 2>&1
cat "$OUTPUTFILE"
