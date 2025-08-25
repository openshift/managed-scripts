#!/bin/bash

# Script Description:
# This script provides the ability to cancel the upgrade policy of a given OpenShift cluster.
# It retrieves the required authentication token, fetches relevant IDs (UUID and Cluster ID), 
# obtains the upgrade policy's UUID, and then proceeds to update the upgrade policy state to "cancelled".

# Usage:
# To utilize this script, invoke it through a managed job using the following command:
# ocm backplane managedjob create operators-lifecycle/update-upgrade-policy-state

# Defined Functions

# Fetch authentication token.
# Output: Returns the authentication token as a string.
fetch_auth_token() {
    oc -n openshift-config get secret pull-secret -o json | jq -r '.data.".dockerconfigjson"' | base64 -d | jq -r '.auths."cloud.openshift.com".auth'
}

# Fetch UUID of the current OpenShift cluster.
get_cluster_uuid() {
    local cluster_uuid
    cluster_uuid=$(oc get clusterversion version -o json | jq -r '.spec.clusterID')
    if [[ -z "$cluster_uuid" ]]; then
        echo "Cannot find the cluster" >&2
        return 1
    fi
    echo "$cluster_uuid"
}

# Using the cluster's UUID, fetch the cluster's ID.
# Params:
#   - Cluster UUID
get_cluster_id() {
    local cluster_uuid="$1"  # Cluster UUID passed as an argument
    local ocm_slug="api/clusters_mgmt/v1/clusters"
    
    # Query OCM API to find the cluster by its UUID
    local cluster_id
    cluster_id=$(curl -sS -G -XGET \
        -H "Content-Type: application/json" \
        -H "Authorization: AccessToken ${CLUSTER_UUID}:${AUTH_TOKEN}" \
        --data-urlencode "search=external_id = '${cluster_uuid}'" \
        "${BASE_URL}/${ocm_slug}" | jq -r '.items[0].id // empty')

    if [[ -z "$cluster_id" ]]; then
        echo "Cluster with UUID ${cluster_uuid} not found in OCM" >&2
        return 1
    fi
    echo "$cluster_id"
}

# Get the UUID of the upgrade policy for the cluster.
# Params:
#   - Cluster ID
get_policy_uuid() {
    local cluster_id="$1"
    local ocm_slug="api/clusters_mgmt/v1/clusters/${cluster_id}/upgrade_policies/"
    local policy_uuid

    policy_uuid=$(curl -sS -XGET \
        -H "Content-Type: application/json" \
        -H "Authorization: AccessToken ${CLUSTER_UUID}:${AUTH_TOKEN}" \
        "${BASE_URL}/${ocm_slug}" | jq -r '.items[]?.id // empty')

    [[ -z "$policy_uuid" ]] && {
        echo "No upgrade policy found for cluster ID ${cluster_id}" >&2
        return 1
    }
    echo "$policy_uuid"
}

# Update the state of the specified upgrade policy to "cancelled".
# Params:
#   - Cluster ID
#   - Policy UUID

update_upgrade_policy() {
    local cluster_id="$1"
    local policy_uuid="$2"
    local ocm_slug="api/clusters_mgmt/v1/clusters/${cluster_id}/upgrade_policies/${policy_uuid}/state"

    curl -sS -XPATCH \
        -H "Content-Type: application/json" \
        -H "Authorization: AccessToken ${CLUSTER_UUID}:${AUTH_TOKEN}" \
        "${BASE_URL}/${ocm_slug}" -d '{
        "value": "cancelled",
        "description": "Manually cancelled by SRE"
    }'
}

# Main logic:

# 1. Dynamically set base URL based on $env early for consistency
BASE_URL="https://api${env:+.stage}.openshift.com"

# 2. Fetch the auth token
AUTH_TOKEN=$(fetch_auth_token) || { echo "Failed to retrieve auth token"; exit 1; }

# 3. Get cluster UUID and ID
CLUSTER_UUID=$(get_cluster_uuid)

# 4. Get cluster ID via API
CLUSTER_ID=$(get_cluster_id "${CLUSTER_UUID}") || exit 1

# 5. Get policy UUID and cancel the upgrade
POLICY_UUID=$(get_policy_uuid "${CLUSTER_ID}") || exit 1
update_upgrade_policy "${CLUSTER_ID}" "${POLICY_UUID}"
