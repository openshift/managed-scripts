#!/bin/bash
#
# Cordon/Uncordon a worker node.
# Input:
#  (Env) WORKER
#    name of the worker node to be (un)cordoned

set -e
set -o nounset
set -o pipefail

if [[ -z "${WORKER}" ]]; then
    echo 'Variable WORKER cannot be blank'
    exit 1
fi
if [[ -z "${ACTION}" ]]; then
    echo 'Variable ACTION cannot be blank'
    exit 1
fi

check_worker(){
    echo "Checking if \"${WORKER}\" is a worker node..."
    
    if (oc get nodes -l node-role.kubernetes.io/worker=,node-role.kubernetes.io/infra!= -oname | grep "${WORKER}") &> /dev/null; then
       echo "[OK] \"${WORKER}\" is a worker node. Proceeding with \"${ACTION}\""
    else
        echo "[Error] \"${WORKER}\" is not a worker node. Exiting script"
        exit 1
    fi
}

cordon_worker(){
    if oc adm cordon "${WORKER}"; then
        echo "[OK] Node \"${WORKER}\" cordoned successfully"
        exit 0
    else
        echo "[ERROR] Something went wrong"
        exit 1
    fi
}

uncordon_worker(){
    if oc adm uncordon "${WORKER}"; then
        echo "[OK] Node \"${WORKER}\" uncordoned successfully"
        exit 0
    else
        echo "[ERROR] Something went wrong"
        exit 1
    fi
}

check_cordon(){
    if [[ $(oc get node "${WORKER}" -o jsonpath='{.spec.taints[?(@.key == "node.kubernetes.io/unschedulable")]}') ]]; then
        echo "[ERROR] Node is already cordoned"
        exit 1
    fi
}

check_uncordon(){
    if ! [[ $(oc get node "${WORKER}" -o jsonpath='{.spec.taints[?(@.key == "node.kubernetes.io/unschedulable")]}') ]]; then
        echo "[ERROR] Node is already uncordoned"
        exit 1
    fi
}

main(){
    check_worker
    if [[ "${ACTION}" == "cordon" ]]; then
        check_cordon
        cordon_worker
    elif [[ "${ACTION}" == "uncordon" ]]; then
        check_uncordon
        uncordon_worker
    else
        echo "The only actions accepted are either 'cordon' or 'uncordon'"
        exit 1
    fi
}

main
