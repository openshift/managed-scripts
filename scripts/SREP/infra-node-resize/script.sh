#!/bin/bash
# This script checks if any tech preview features are enabled through feature sets.

set -e
set -o nounset
set -o pipefail

# fetch the infra machinepools
get_machinepool() {
    echo 'FETCHING INFRA MACHINEPOOLS...'
    NAMESPACE=$(oc get ns | grep "$CLUSTER_ID" | awk '{print $1}')
    oc -n "$NAMESPACE" get machinepool
    INFRA_MACHINEPOOL=$(oc -n "$NAMESPACE"  get machinepool -o json | jq -r '.items[] | select(.spec.name=="infra") | .metadata.name')
    oc -n "$NAMESPACE" get machinepool "$INFRA_MACHINEPOOL" -o json | jq -r ".spec.platform.type"
}

# update the yaml file
update_cluster_infra_yaml() {
    echo 'UPDATING THE YAML FILE FOR TEMPORARY MACHINEPOOL...'
    oc -n "$NAMESPACE" get machinepool "$INFRA_MACHINEPOOL" -o yaml > /tmp/cluster-infra.yaml
    yq -i 'del(.metadata.creationTimestamp) | del(.metadata.finalizer) | del(.metadata.resourceVersion) | del(.metadata.generation) | del(.metadata.selfLink) | del(.metadata.uid) | del(.status)' /tmp/cluster-infra.yaml
    cat /tmp/cluster-infra.yaml 
    CLOUD=$(oc -n "$NAMESPACE" get machinepool "$INFRA_MACHINEPOOL" -o json | jq -r '.spec.platform | keys_unsorted[0]')
    yq -i ".metadata.name |= . + 2 | .spec.name |= . + 2 | .spec.platform.$CLOUD.type |= env(INSTANCE_SIZE)" /tmp/cluster-infra.yaml 
}

# create the temporary machinepool
create_temp_machinepool() {
    echo 'CREATING TEMPORARY MACHINEPOOL...'
    oc -n "$NAMESPACE" create -f /tmp/cluster-infra.yaml
    while [[ ! -z "$(oc get machinepool -n "$NAMESPACE" "$INFRA_MACHINEPOOL" -o=jsonpath='{.status.machineSets[0].errorMessage}')" ]];
    do
        echo 'MACHINES ARE STILL NOT CORRECTLY PROVISIONED...'
        timeout 10
    done
    oc -n "$NAMESPACE" get machinepool
}

# delete the original machinepool
delete_original_machinepool() {
    echo 'DELETING THE ORIGINAL MACHINEPOOL...'
    oc scale --replicas 0 machinepool "$INFRA_MACHINEPOOL" -n "$NAMESPACE"
    oc -n "$NAMESPACE" get machinepool
    while [[ ! -z "$(oc get machinepool -n "$NAMESPACE" "$INFRA_MACHINEPOOL" -o=jsonpath='{.status.machineSets[0].errorMessage}')" ]];
    do
        echo 'MACHINES ARE STILL NOT PROPERL DELETED...'
        timeout 10
    done
    oc -n "$NAMESPACE" delete machinepool "$INFRA_MACHINEPOOL"
    echo 'ORIGINAL MACHINEPOOLS WHICH ARE NOT RESIZED ARE DELETED...'
    oc -n "$NAMESPACE" get machinepool
}

# update yaml file cluster 
update_new_infra_yaml() {
    echo 'UPDATING YAML FILE...'
    yq eval '.metadata.name |= sub("2$"; "") | .spec.name |= sub("2$"; "")' -i /tmp/cluster-infra.yaml 
    cat /tmp/cluster-infra.yaml
}

# create new machinepool
create_new_machinepool() {
    echo 'CREATING NEW MACHINEPOOL...'
    oc -n "$NAMESPACE" create -f /tmp/cluster-infra.yaml
    while [[ ! -z "$(oc get machinepool -n "$NAMESPACE" "$INFRA_MACHINEPOOL" -o=jsonpath='{.status.machineSets[0].errorMessage}')" ]];
    do
        echo 'MACHINES ARE STILL NOT CORRECTLY PROVISIONED...'
        timeout 10
    done
}

# delete temporary machinepool 
delete_temp_machinepool() {
    echo 'DELETING TEMPORARY MACHINEPOOL...'
    oc scale --replicas 0 machinepool "${INFRA_MACHINEPOOL}"2 -n "$NAMESPACE"
    oc -n "$NAMESPACE" get machinepool
    while [[ ! -z "$(oc get machinepool -n "$NAMESPACE" "$INFRA_MACHINEPOOL" -o=jsonpath='{.status.machineSets[0].errorMessage}')" ]];
    do
        echo 'MACHINES ARE STILL NOT PROPERLY DELETED...'
        timeout 10
    done
    oc -n "$NAMESPACE" delete machinepool "${INFRA_MACHINEPOOL}"2 
    echo 'TEMPORARY MACHINEPOOLS ARE DELETED...'
}

# check the state of machinepools
verify_machinepools() {
    echo 'VERIFYING MACHINEPOOLS...'
    echo 'FETCHING MACHINEPOOL NAME..'
    INFRA_MACHINEPOOL_NAME=$(oc -n "$NAMESPACE"  get machinepool -o json | jq -r '.items[] | select(.spec.name=="infra") | .metadata.name')
    echo "THIS INFRA MACHINEPOOL HAS BEEN RESIZED $INFRA_MACHINEPOOL_NAME"
    INFRA_MACHINEPOOL_SIZE=$(oc -n "$NAMESPACE" get machinepool "$INFRA_MACHINEPOOL" -o=jsonpath="{.spec.platform.$CLOUD.type}")
    echo 'CHECKING IF IT HAS BEEN RESIZED CORRECTLY..'
    if [[ "$INFRA_MACHINEPOOL_SIZE" == "$INSTANCE_SIZE" ]]; then
        echo 'INFRA RESIZE HAS BEEN SUCCESSFULLY DONE..'
    else
        echo 'INFRA RESIZE UNSUCCESSFUL..'
    fi
}

main() {
  get_machinepool
  update_cluster_infra_yaml
  create_temp_machinepool
  delete_original_machinepool
  update_new_infra_yaml
  create_new_machinepool
  delete_temp_machinepool
  verify_machinepools
  echo "Succeed."
  exit 0
}

main "$@"
