#!/bin/bash

# Variables
CLUSTER_NAME="$1"
DESIRED_STATE="$2"

# Usage: 
# ./script.sh DESIRED_STATE=scheduled 
# `scheduled` is the desired state you want to set for the cluster's upgrade policy.
# 
# Possible values of the upgrade policy state can include "started", "scheduled", "cancelled" etc. 
# Ensure that you provide a state recognized by your OpenShift Cluster Manager instance.

# Defined Functions:

# Fetch the unique identifier (UUID) of the current OpenShift cluster.
get_cluster_uuid() {
    oc get clusterversion version -o json | jq -r '.spec.clusterID'
}

# Using the cluster's UUID, fetch the cluster's ID.
get_cluster_id() {
    ocm list clusters --parameter search="external_id is '${1}'" --columns id --padding 20 --no-headers
}

# Get upgrade policies associated with the specified cluster ID.
get_policy_response() {
    ocm get "/api/clusters_mgmt/v1/clusters/${1}/upgrade_policies/"
}

# Count the number of upgrade policies available for the current cluster.
get_policy_count() {
    echo "$1" | jq '.size'
}

# Fetch the UUID of the first available upgrade policy for the cluster.
get_policy_uuid() {
    echo "$1" | jq -r '.items[0].id'
}

# Fetch the current state of the specified upgrade policy.
get_current_state() {
    ocm get "$1" | jq -r '.value'
}

# Update the state of the specified upgrade policy to the desired state.
update_upgrade_policy() {
    local ocm_slug="$1"
    local desired_state="$2"
    local payload="{ \"value\": \"${desired_state}\", \"description\": \"Manually updated by SRE\" }"
    ocm patch "${ocm_slug}" --body "${payload}" --type application/json
}

# Parse the arguments passed to the script to determine the desired state.
parse_arguments() {
    for arg in "$@"; do
        case "$arg" in
            DESIRED_STATE=started)
                DESIRED_STATE="started"
                ;;
            DESIRED_STATE=scheduled)
                DESIRED_STATE="scheduled"
                ;;
            DESIRED_STATE=cancelled)
                DESIRED_STATE="cancelled"
                ;;
            DESIRED_STATE=*)
                echo "Invalid value for DESIRED_STATE. Allowed values are 'started', 'scheduled', or 'cancelled'."
                exit 1
                ;;
            *)
                echo "Invalid argument format. Usage: $0 DESIRED_STATE=<DESIRED_STATE>"
                echo "Where <DESIRED_STATE> is one of 'started', 'scheduled', or 'cancelled'."
                exit 1
                ;;
        esac
    done

    # Validate that a desired state argument is provided.
    if [ -z "${DESIRED_STATE}" ]; then
        echo "Usage: $0 DESIRED_STATE=<DESIRED_STATE>"
        echo "Where <DESIRED_STATE> is one of 'started', 'scheduled', or 'cancelled'."
        exit 1
    fi
}

# Fetch data related to the cluster and its upgrade policies.
fetch_cluster_data() {
    CLUSTER_UUID=$(get_cluster_uuid)
    CLUSTER_ID=$(get_cluster_id "${CLUSTER_UUID}")
    POLICY_RESPONSE=$(get_policy_response "${CLUSTER_ID}")
    POLICY_COUNT=$(get_policy_count "${POLICY_RESPONSE}")

    # Check for existing upgrade policies, exit if none found.
    if [ "${POLICY_COUNT}" -eq 0 ]; then
        echo "No upgrade policies found for the current cluster. Exiting."
        exit 1
    fi
}

# Compare the current policy state to the desired state and perform an update if necessary.
update_policy_if_required() {
    POLICY_UUID=$(get_policy_uuid "${POLICY_RESPONSE}")
    OCM_SLUG="/api/clusters_mgmt/v1/clusters/${CLUSTER_ID}/upgrade_policies/${POLICY_UUID}/state"
    CURRENT_STATE=$(get_current_state "${OCM_SLUG}")

    echo "Current upgrade_policy state: ${CURRENT_STATE}"

    if [ "${CURRENT_STATE}" == "${DESIRED_STATE}" ]; then
        echo "Upgrade policy is already in the desired state: ${DESIRED_STATE}"
        exit 0
    fi

    update_upgrade_policy "${OCM_SLUG}" "${DESIRED_STATE}"
    echo "Upgrade policy state updated from ${CURRENT_STATE} to ${DESIRED_STATE}."
}

# Main logic:

# 1. Parse provided arguments to get desired state.
parse_arguments "$@"

# 2. Fetch necessary cluster data and its related upgrade policy info.
fetch_cluster_data

# 3. Update the upgrade policy state if required.
update_policy_if_required
