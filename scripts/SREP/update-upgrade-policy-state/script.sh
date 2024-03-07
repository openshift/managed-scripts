#!/bin/bash

# Script Description:
# This script provides the ability to cancel the upgrade policy of a given OpenShift cluster.
# It retrieves the required authentication token, fetches relevant IDs (UUID and Cluster ID), 
# obtains the upgrade policy's UUID, and then proceeds to update the upgrade policy state to "cancelled".

# Usage:
# To utilize this script, invoke it through a managed job using the following command:
# ocm backplane managedjob create SREP/update-upgrade-policy-state

# Defined Functions

# Fetch authentication token.
# Output: Returns the authentication token as a string.
fetch_auth_token() {
    oc -n openshift-config get secret pull-secret -o json --as backplane-cluster-admin | jq -r '.data.".dockerconfigjson"' | base64 -d | jq -r '.auths."cloud.openshift.com".auth'
}

# Fetch UUID of the current OpenShift cluster.
get_cluster_uuid() {
    oc get clusterversion version -o json | jq -r '.spec.clusterID'
}

# Using the cluster's UUID, fetch the cluster's ID.
# Params:
#   - Cluster UUID
get_cluster_id() {
    ocm list clusters --parameter search="external_id is '${1}'" --columns id --padding 20 --no-headers
}

# Get the UUID of the upgrade policy for the cluster.
# Params:
#   - Cluster ID
get_policy_uuid() {
    local policy_uuid
    policy_uuid=$(ocm get "/api/clusters_mgmt/v1/clusters/${1}/upgrade_policies/" | jq '.items[]? | .id' | tr -d '"')
    if [[ -z "$policy_uuid" ]]; then
        echo "No upgrade policy found for cluster ID ${1}" >&2
        return 1
    fi
    echo "$policy_uuid"
}

# Update the state of the specified upgrade policy to "cancelled".
# Params:
#   - Cluster ID
#   - Policy UUID
update_upgrade_policy() {
    local ocm_slug="api/clusters_mgmt/v1/clusters/${1}/upgrade_policies/${2}/state"
    curl -XPATCH \
        -H "Content-Type: application/json" \
        -H "Authorization: AccessToken ${CLUSTER_UUID}:${AUTH_TOKEN}" \
        "https://api.stage.openshift.com/${ocm_slug}" -d '{
        "value": "cancelled",
        "description": "Manually cancelled by SRE"
    }'
}

# Main logic:

# 1. Fetch the auth token.
AUTH_TOKEN=$(fetch_auth_token)
if [ -z "$AUTH_TOKEN" ]; then
    echo "Failed to retrieve the authentication token. Exiting."
    exit 1
fi

# 2. Get the cluster UUID.
CLUSTER_UUID=$(get_cluster_uuid)

# 3. Get the cluster ID.
CLUSTER_ID=$(get_cluster_id "${CLUSTER_UUID}")

# 4. Get the policy UUID.
POLICY_UUID=$(get_policy_uuid "${CLUSTER_ID}")
if [[ $? -ne 0 ]]; then
    echo "Error fetching the policy UUID. Exiting."
    exit 1
fi

# 5. Cancel the upgrade policy.
update_upgrade_policy "${CLUSTER_ID}" "${POLICY_UUID}"
