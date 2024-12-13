#!/bin/bash

set -e
set -o errexit
set -o nounset
set -o pipefail

## Input validation
### Check the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <pod_name> <namespace>"
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

## Delete the pod
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
  delete_pod
}

main