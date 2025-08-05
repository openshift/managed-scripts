#!/bin/bash
# This job outlines the procedure for increasing the PVC size of an RHACS (Red Hat Advanced Cluster Security) instance. 
# It includes steps for inspecting logs, retrieving the current PVC, editing the PVC size, and verifying the resize process.
set -euxo pipefail

if [[ -z "${NEW_SIZE}" ]]; then
    echo 'Env Variable NEW_SIZE cannot be blank'
    exit 1
fi

# Function to check if a string is a valid size format
function validate_size_format() {
    # Regex pattern for validating size format (e.g., 100Mi or 1G)
    local pattern='^[0-9]+[KMGTPE]?i?$'
    if [[ $1 =~ $pattern ]]; then
        echo "Valid size format"
    else
        echo "Invalid size format"
        exit 1
    fi
}

# Validate the format of NEW_SIZE
if ! validate_size_format "$NEW_SIZE"; then
    echo "Error: Invalid format for NEW_SIZE."
    exit 1
fi

# Function to convert size with suffix to bytes
# It supports both Kilo, Mega, Giga, Tera, Peta, and Exa sizes and Kibi, Mebi, Gibi, Tebi, Pebi, and Exbi sizes
function size_to_bytes() {
    local size_with_suffix="$1"
    local size="${size_with_suffix//[a-zA-Z]/}"  # Remove suffix
    local suffix="${size_with_suffix//[0-9.]}"  # Extract suffix
    case $suffix in
        K|KB|Ki) echo "$((size * 1024))" ;;
        M|MB|Mi) echo "$((size * 1024 * 1024))" ;;
        G|GB|Gi) echo "$((size * 1024 * 1024 * 1024))" ;;
        T|TB|Ti) echo "$((size * 1024 * 1024 * 1024 * 1024))" ;;
        P|PB|Pi) echo "$((size * 1024 * 1024 * 1024 * 1024 * 1024))" ;;
        E|EB|Ei) echo "$((size * 1024 * 1024 * 1024 * 1024 * 1024 * 1024))" ;;
        *) echo "$size" ;;
    esac
}

function get-observability-logs() {
    oc logs statefulset/prometheus-obs-prometheus --namespace rhacs-observability > logs.txt
}

function get-pvc() {
    PVC=$(oc get pvc -l app=prometheus --namespace rhacs-observability -o json | awk '{print $1}')
}

function edit-pvc-size() {
    # Convert sizes to bytes for comparison
    new_size_bytes=$(size_to_bytes "$NEW_SIZE")
    current_size=$(oc get pvc "$PVC" --namespace rhacs-observability -o json | jq '.spec.resources.requests.storage')
    current_size_bytes=$(size_to_bytes "$current_size")

    # Check if NEW_SIZE is larger than the current size
    if (( new_size_bytes <= current_size_bytes )); then
        echo "Error: NEW_SIZE should be strictly larger than the current size of the PVC."
        exit 1
    fi

    oc patch pvc "$PVC" --namespace rhacs-observability --type merge --patch "{\"spec\":{\"resources\":{\"requests\":{\"storage\":\"${NEW_SIZE}\"}}}}"
}

# Verify the new PVC size is NEW_SIZE
function verify-resize() {
    size=$(oc get pvc "$PVC" --namespace rhacs-observability -o json | jq '.spec.resources.requests.storage')
    if [[ $size == "$NEW_SIZE" ]]; then
        echo "PVC size has been successfully updated to $NEW_SIZE"
    else
        echo "PVC size has not been updated"
        exit 1
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
