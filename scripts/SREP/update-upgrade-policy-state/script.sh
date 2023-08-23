#!/bin/bash

# Variables
CLUSTER_NAME="$1"
DESIRED_STATE="$2"

# Check if either CLUSTER_NAME or DESIRED_STATE is not provided as an argument
if [ -z "$CLUSTER_NAME" ] || [ -z "$DESIRED_STATE" ]; then
    # If either variable is empty, print the correct usage of the script
    echo "Usage: $0 <CLUSTER_NAME> <DESIRED_STATE>"
    exit 1
fi

# Fetch the cluster UUID
CLUSTER_UUID=$(oc get clusterversion version -o json | jq -r '.spec.clusterID')

# Fetch the auth token
AUTH_TOKEN=$(oc -n openshift-config get secret pull-secret -o json | jq -r '.data.".dockerconfigjson"' | base64 -d | jq -r '.auths."cloud.openshift.com".auth')

# Fetch cluster ID
CLUSTER_ID=$(ocm list clusters --parameter search="external_id is '${CLUSTER_UUID}'" --columns id --padding 20 --no-headers)

# Fetch upgrade policies for the cluster and check if any exist
POLICY_RESPONSE=$(ocm get /api/clusters_mgmt/v1/clusters/${CLUSTER_ID}/upgrade_policies/)
POLICY_COUNT=$(echo "$POLICY_RESPONSE" | jq '.size')

# If there are no upgrade policies, print a message and exit
if [ "$POLICY_COUNT" -eq 0 ]; then
    echo "No upgrade policies found for cluster ${CLUSTER_NAME}. Exiting."
    exit 1
fi

# Fetch the ID of the upgrade policy
POLICY_UUID=$(echo "$POLICY_RESPONSE" | jq -r '.items[0].id')

# Construct OCM URL slug
OCM_SLUG="/api/clusters_mgmt/v1/clusters/${CLUSTER_ID}/upgrade_policies/${POLICY_UUID}/state"

# Get the current upgrade_policy state using ocm
CURRENT_STATE=$(ocm get ${OCM_SLUG} | jq -r '.value')

echo "Current upgrade_policy state: $CURRENT_STATE"

# Check if the current state is already the desired state
if [ "$CURRENT_STATE" == "$DESIRED_STATE" ]; then
    echo "Upgrade policy is already in the desired state: $DESIRED_STATE"
    exit 0
fi

# Update the upgrade policy to the desired state using ocm
OCM_UPDATE_PAYLOAD=$(echo "{ \"value\": \"$DESIRED_STATE\", \"description\": \"Manually updated by SRE\" }" | base64 -w 0)
ocm patch ${OCM_SLUG} --body ${OCM_UPDATE_PAYLOAD} --type application/json

# Inform the user of the state change
echo "Upgrade policy state updated from $CURRENT_STATE to $DESIRED_STATE."