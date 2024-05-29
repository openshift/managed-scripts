#!/bin/bash
#
# Drain and Reboot a worker node.
# Input:
#  (Env) WORKER
#    name of the worker node
#  (Env) ACTION
#    action to execute on the worker node
#  (Env) DRAINMODE
#    drain options to execute on the worker node

set -e
set -o nounset
set -o pipefail

CURRENTDATE=$(date +"%Y-%m-%d %T")

if [[ -z "${WORKER}" ]]; then
    echo "[Error] The WORKER node name has not been provided."
    echo "Usage:"
    echo "ocm backplane managedjob create CEE/cordon-drain-reboot-worker-node -p WORKER='<node_name>' -p ACTION='<action>' [-p DRAINMODE='<drain parameters>']"
    echo
    echo "List of Actions:"
    echo "- cordon"
    echo "- uncordon"
    echo "- drain"
    echo "- reboot"
    exit 1
fi

if [[ -z "${ACTION}" ]]; then
    echo "[Error] Please inform which ACTION you want to perfom on the worker node ${WORKER} from the list below:"
    echo "- cordon"
    echo "- uncordon"
    echo "- drain"
    echo "- reboot"
    exit 1
fi

start_job(){
    echo "Job started at $CURRENTDATE"
    echo ".................................."
    echo
}

finish_job(){
    echo
    echo ".................................."
    echo "Job finished at $CURRENTDATE"
}

## Function which checks if the node is a Worker node
check_worker(){

    echo "Checking if ${WORKER} is a worker node..."
    
    if (oc get nodes -l node-role.kubernetes.io/worker=,node-role.kubernetes.io/infra!= -oname | grep "${WORKER}") &> /dev/null; then
        echo "[OK] ${WORKER} is a worker node."
        echo
    else
        echo "[Error] ${WORKER} is not a worker node. Please ensure you are providing the correct name"
        exit 1
    fi

}

## Function which check if the node is already cordoning
check_cordon(){
    if [[ $(oc get node "${WORKER}" -o jsonpath='{.spec.taints[?(@.key == "node.kubernetes.io/unschedulable")]}') ]]; then
        echo "[Error] Node is already cordoned"
        exit 1
    fi
}

## Function which check if the node is already uncordoning
check_uncordon(){
    if ! [[ $(oc get node "${WORKER}" -o jsonpath='{.spec.taints[?(@.key == "node.kubernetes.io/unschedulable")]}') ]]; then
        echo "[Error] Node is already uncordoned"
        exit 1
    fi
}

## Function which cordon the worker node
cordon_worker(){
    if oc adm cordon "${WORKER}"; then
        echo "[OK] Node ${WORKER} cordoned successfully"
        exit 0
    else
        echo "[Error] Something went wrong"
        exit 1
    fi
}

## Function which uncordon the worker node
uncordon_worker(){
    if oc adm uncordon "${WORKER}"; then
        echo "[OK] Node ${WORKER} uncordoned successfully"
        exit 0
    else
        echo "[Error] Something went wrong"
        exit 1
    fi
}

## Function which drains the node bypassing the PDB check
drain_worker(){

    echo "Draining node ${WORKER} with drain mode '${DRAINMODE}'"
    oc adm drain "${WORKER}" "${DRAINMODE}"

    if [ $? -eq 0 ]; then 
        echo "[OK] Node ${WORKER} drained successfully."
        echo
    else
        echo "[Error] Something went wrong."
        exit 1
    fi

}

## Function which reboot the node
reboot_worker(){

    echo "Rebooting node ${WORKER}..."

    cat <<EOF | oc -n default debug node/$WORKER
    chroot /host
    reboot
EOF

}

check_reboot(){

    echo
    echo "Checking node reboot..."

    rebootCount=0
    rebootStatus=0
    t0=$(date '+%s')
    timeout_secs=300

    while [[ $(("$timeout_secs" + "$t0" - "$(date '+%s')")) -gt 0 ]]; do
        nodeStatus=$(oc get nodes "${WORKER}" -ojsonpath='{.status.conditions[3].status}{"\n"}')
            if [ "${nodeStatus}" != "True" ] ; then 
                rebootCount=1
                echo "Rebooting..."
                sleep 2
            else
                if [ "${rebootCount}" -eq 1 ] ; then
                    rebootStatus=1
                    echo "Node Rebooted!"
                    break
                fi
            fi
    done
    
    if [ "${rebootStatus}" -eq 0 ] ; then
        echo "[Error] Reboot timeout..."
        exit 1
    fi

}

main(){
    start_job
    check_worker
    if [[ "${ACTION}" == "cordon" ]]; then
        check_cordon
        cordon_worker
    elif [[ "${ACTION}" == "uncordon" ]]; then
        check_uncordon
        uncordon_worker
    elif [[ "${ACTION}" == "drain" ]]; then
        drain_worker
    elif [[ "${ACTION}" == "reboot" ]]; then
        drain_worker
        reboot_worker
        check_reboot
    else
        echo "[Error] The only actions accepted are:"
        echo "- cordon"
        echo "- uncordon"
        echo "- drain"
        echo "- reboot"
        exit 1
    fi
    finish_job
}

main
