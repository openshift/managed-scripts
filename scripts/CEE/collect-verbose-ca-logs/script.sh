#!/bin/bash

# Set variables
GREEN="\033[32m"
RESET="\033[0m"
NAMESPACE="openshift-machine-api"
CA_NAME="default"

# Get current logVerbosity value
current_log_verbosity=$(oc get ca $CA_NAME -o jsonpath='{.spec.logVerbosity}')

# Check if current_log_verbosity is empty
if [ -z "$current_log_verbosity" ]; then
  echo "Failed to retrieve current logVerbosity value."
  exit 1
fi

echo
echo "CURRENT LOG VERBOSITY = $current_log_verbosity"
echo

# Update logVerbosity to 6
oc patch ca $CA_NAME --type='json' -p='[{"op": "replace", "path": "/spec/logVerbosity", "value": 6}]'

updated_log_verbosity=$(oc get ca $CA_NAME -o jsonpath='{.spec.logVerbosity}')
echo
echo "UPDATED LOG VERBOSITY = $updated_log_verbosity"
echo

# Wait for the update to take effect
echo "Waiting for the log verbosity to update..."
sleep 30

# Get the name of the Cluster Autoscaler pod
CA_POD=$(oc get pods -n openshift-machine-api | grep cluster-autoscaler-default | awk '{print $1}')

# Collect logs for the next 6 minutes
echo
echo "Collecting logs for the next 6 minutes..."
echo

sleep 360

echo "---------------------"
echo "LOG COLLECTION: START"
echo "---------------------"
echo
CA_LOGS=$(oc logs -n $NAMESPACE "$CA_POD" --since=6m)

#Collect the list of nodes from the cluster
node_names=$(oc get nodes -o jsonpath='{.items[*].metadata.name}')

for node in $node_names; 
do
    echo -e "${GREEN}Searching for node: $node ${RESET}"
    # Step 3: Display all the log lines where the node name is present
    echo "$CA_LOGS" | grep "$node"
    echo
done

echo
echo "---------------------"
echo "LOG COLLECTION: END"
echo "---------------------"

echo

# Revert logVerbosity to previous value
oc patch ca $CA_NAME --type='json' -p="[{'op': 'replace', 'path': '/spec/logVerbosity', 'value': $current_log_verbosity}]"

# Wait for the update to take effect
echo
echo "Waiting for the log verbosity to be reverted back..."
echo

sleep 30

current_log_verbosity=$(oc get ca $CA_NAME -o jsonpath='{.spec.logVerbosity}')
echo "REVERTED LOG VERBOSITY = $current_log_verbosity"
echo
