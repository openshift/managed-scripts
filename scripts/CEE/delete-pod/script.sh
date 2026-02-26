#!/bin/bash

set -e
set -o errexit
set -o nounset
set -o pipefail

## Input validation
if ! declare -p FLAGS &>/dev/null || [[ -z "${FLAGS}" ]]; then
  FLAGS=""
fi

# If --force is in FLAGS, set FORCE_FLAG to true
FORCE_FLAG=false
if [[ "$FLAGS" =~ --force ]]; then
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
  echo -e "\n[INFO] Checking replicaset owning the pod \"${POD_NAME}\" from \"${NAMESPACE}\" namespace."
  
  local owner_kind
  owner_kind=$(oc get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.ownerReferences[0].kind}' 2>/dev/null || echo "")  
  
  if [[ "$owner_kind" == "ReplicaSet" ]]; then
    echo "[INFO] Pod '${POD_NAME}' is owned by a ReplicaSet."
  else
    echo "[WARN] Pod '${POD_NAME}' is not owned by a ReplicaSet."

    if [[ "$FORCE_FLAG" != true ]]; then
      echo "[ERROR] Deletion blocked. Use --force to override." >&2
      exit 1
    else
      echo "[INFO] --force flag detected. Proceeding with deletion."
    fi
  fi
}

## Delete pod
delete_pod(){
  echo -e "\n[INFO] Deleting pod \"${POD_NAME}\" from \"${NAMESPACE}\" namespace."
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