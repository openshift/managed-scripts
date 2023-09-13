#!/bin/bash

set -e
set -o nounset
set -o pipefail

if [[ -z "${NODE}" ]]; then
    echo 'Variable NODE cannot be blank'
    exit 1
fi

if [[ -z "${MACHINE}" ]]; then
    echo 'Variable MACHINE cannot be blank'
    exit 1
fi

check_worker_node(){
    echo "Verifying that the \"${NODE}\" is not a master nor a infra node..."
    if(oc get nodes --selector='!node-role.kubernetes.io/master,!node-role.kubernetes.io/infra' | grep "${NODE}") &> /dev/null; then
        echo "[OK] \"${NODE}\" is not a master nor a infra node. Proceeding with next check"
    else
        echo "[Error] \"${NODE}\" is a master or a infra node or the node it's not present so it cannot be deleted. Exiting script"
        exit 1
    fi

}

check_node(){
    echo "Checking if the \"${MACHINE}\" is a machine present on the cluster..."
    if(oc get machines -n openshift-machine-api | grep "${MACHINE}") &> /dev/null; then
        echo "[OK] \"${MACHINE}\" is present on the cluster. Proceeding with next check"
    else
        echo "[Error] \"${MACHINE}\" is not present on the cluster. Exiting script"
        exit 1
    fi
}


check_machine(){
    echo "Checking if the \"${MACHINE}\" is the machine associated to the correct node..."

    if (oc get nodes -o jsonpath='{range .items..metadata}{.name}{" "}{.annotations.machine\.openshift\.io/machine}{"\n"}{end}' | grep "${MACHINE}" | awk '{print $(NF)}') &> /dev/null; then
        echo "[OK] \"${MACHINE}\" is the correct one Proceeding with next check"
    else
        echo "[Error] \"${MACHINE}\" is not correct, please, check that you have provided the correct values. Exiting script"
        exit 1
    fi
}

delete_machine(){
    echo "Deleting the machine to be recreated"
    oc delete machine -n openshift-machine-api $MACHINE
}

main(){
    check_worker_node
    check_node
    check_machine
    delete_machine
}

main

