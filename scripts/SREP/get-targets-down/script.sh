#!/bin/bash

set -euo pipefail

TOKEN="$(oc -n openshift-monitoring sa get-token prometheus-k8s)"
PROMETHEUS_HOST="$(oc -n openshift-monitoring get route prometheus-k8s -o jsonpath='{.spec.host}')"

TARGETS_JSON="$(curl -G -s -k -H "Authorization: Bearer $TOKEN" "https://$PROMETHEUS_HOST/api/v1/targets")"
TARGETS_DOWN="$(jq -r '.data.activeTargets[] | select(.health=="down") | .labels.pod' <<< "$TARGETS_JSON")"

echo "Targets down:"
echo -e "NAMESPACE POD\n$TARGETS_DOWN" | column -t -s' '

if [[ "$TARGETS_DOWN" == "" ]]; then
    echo -e "\n\nNo targets down reported. All targets:"
    ALL_TARGETS="$(jq -r '.data.activeTargets[] | .labels.namespace + " " + .labels.pod' <<< "$TARGETS_JSON")"
    echo -e "NAMESPACE POD\n$ALL_TARGETS" | column -t -s' '
fi

exit 0