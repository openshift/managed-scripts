#!/bin/bash
# This job outlines the procedure for increasing the PVC size of an RHACS (Red Hat Advanced Cluster Security) instance. 
# It includes steps for inspecting logs, retrieving the current PVC, editing the PVC size, and verifying the resize process.
set -euxo pipefail

if [[ -z "${NEW_SIZE}" ]]; then
    echo 'Variable NEW_SIZE cannot be blank'
    exit 1
fi

function get-observability-logs() {
    oc logs statefulset/prometheus-obs-prometheus --namespace rhacs-observability > logs.txt
}

function get-pvc() {
    PVC=$(oc get pvc -l app=prometheus --namespace rhacs-observability -o json | awk '{print $1}')
}

function edit-pvc-size() {
    oc patch pvc $PVC --namespace rhacs-observability --type merge --patch "{\"spec\":{\"resources\":{\"requests\":{\"storage\":\"${NEW_SIZE}\"}}}}"
}

# Verify the new PVC size is NEW_SIZE
function verify-resize() {
    size=$(oc get pvc $PVC --namespace rhacs-observability -o json | jq '.spec.resources.requests.storage')
    if [[ $size == $NEW_SIZE ]]; then
        echo "PVC size has been successfully updated to $NEW_SIZE"
    else
        echo "PVC size has not been updated"
    fi
}

# rollout restart the prometheus-obs-prometheus statefulset
function restart-prometheus() {
    oc rollout restart statefulset/prometheus-obs-prometheus --namespace rhacs-observability
}

get-observability-logs
get-pvc
edit-pvc-size
verify-resize
restart-prometheus