#!/bin/bash

set -euo pipefail

TOKEN="$(oc -n openshift-monitoring create token prometheus-k8s)"

TARGETS_JSON="$(curl -G -s -k -H "Authorization: Bearer $TOKEN" "https://prometheus-k8s.openshift-monitoring.svc.cluster.local:9091/api/v1/targets")"
TARGETS_DOWN="$(jq -r '.data.activeTargets[] | select(.health=="down") | .labels.pod' <<< "$TARGETS_JSON")"

echo "Targets down:"
echo -e "NAMESPACE POD\n$TARGETS_DOWN" | column -t -s' '

if [[ "$TARGETS_DOWN" == "" ]]; then
    echo -e "\n\nNo targets down reported. All targets:"
    ALL_TARGETS="$(jq -r '.data.activeTargets[] | .labels.namespace + " " + .labels.pod' <<< "$TARGETS_JSON")"
    echo -e "NAMESPACE POD\n$ALL_TARGETS" | column -t -s' '
fi

exit 0
