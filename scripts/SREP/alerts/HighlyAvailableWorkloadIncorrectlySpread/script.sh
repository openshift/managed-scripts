#!/bin/bash

set -eEuo pipefail

DELETE=${DELETE:-}

NODES_DICT=$(oc get po -ojson  -n "${NS}" | jq --arg WORKLOAD "$WORKLOAD" '[.items[] | select( .metadata.name | test($WORKLOAD + ".*"))]' | jq '[ group_by( .spec.nodeName )[] | {( .[0].spec.nodeName ): length }]' | jq 'unique | reduce .[] as $item ({}; . + $item)')
NODE=$( echo "${NODES_DICT}" | jq -r 'to_entries | sort_by(.value)| .[-1].key')

if [[ -n "${DELETE}" ]]; then
  oc adm cordon "$NODE"
  trap "oc adm uncordon ${NODE}" EXIT
fi

POD=$(oc -n "$NS" get -o wide pods | grep "$WORKLOAD.*$NODE" | cut -f1 -d ' ' | head -n 1)

set -x
oc get node -Lfailure-domain.beta.kubernetes.io/zone --no-headers | awk '{zone=$6; print zone}' | uniq | wc -l
set +x

PVC=$(oc get -n "$NS" pod "$POD" -ojson | jq -r '.spec.volumes[] | select(.persistentVolumeClaim!=null) | .persistentVolumeClaim.claimName')

if [[ -z ${DELETE} ]]; then
        echo "was going to delete po $POD and pvc $PVC"
        echo "but DELETE was not set."
        exit
fi

oc delete -n "$NS" pod "$POD"
oc delete -n "$NS" persistentvolumeclaims "$PVC"
