#!/bin/bash

set -e
set -o errexit
set -o nounset
set -o pipefail

## Input validation
### Check the correct number of arguments is provided
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: $0 <pod_name> <namespace> [--force]"
  exit 1
fi

POD_NAME=$1
NAMESPACE=$2
FORCE_FLAG=false

# Check if force flag is provided
if [[ "${3:-}" == "--force" ]]; then
  FORCE_FLAG=true
fi

if [[ -z "${POD_NAME:-}" ]]; then
    echo 'Variable POD_NAME cannot be blank'
    exit 1
fi

if [[ -z "${NAMESPACE:-}" ]]; then
    echo 'Variable NAMESPACE cannot be blank'
    exit 1
fi

### Check namespace is "openshift-*"
if [[ ! "$NAMESPACE" =~ ^openshift-.*$ ]]; then
  echo "The namespace must start with 'openshift-'"
  exit 1
fi

## Validate if pod is owned by a replicaset
check_owned_by_replicaset(){
  echo -e "\nChecking replicaset owning the pod \"${POD_NAME}\" from \"${NAMESPACE}\" namespace."
  local owner
  owner=$(oc get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.ownerReferences[0].kind}' || true)
  
  if [[ "$owner" == "ReplicaSet" ]]; then
    echo "Pod '$POD_NAME' is owned by a ReplicaSet."
    if [ "$FORCE_FLAG" = false ]; then
      echo "Use the --force flag to bypass the validation."
      exit 1
    fi
  else
    echo "Pod '$POD_NAME' is not owned by a ReplicaSet, proceeding with deletion."
  fi
}

## Delete pod
delete_pod(){
  echo -e "\nDeleting pod \"${POD_NAME}\" from \"${NAMESPACE}\" namespace."
  oc delete pod "$POD_NAME" -n "$NAMESPACE"

  if [ $? -eq 0 ]; then
    echo -e "\n[SUCCESS] Pod '$POD_NAME' successfully deleted from namespace '$NAMESPACE'."
  else
    echo -e "\n[ERROR] Failed to delete pod '$POD_NAME' from namespace '$NAMESPACE'."
  fi
}

main(){
  check_owned_by_replicaset
  delete_pod
}

main