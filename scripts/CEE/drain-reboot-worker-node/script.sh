#!/bin/bash
#
# Drain and Reboot a worker node.
# Input:
#  (Env) WORKER
#    name of the worker node to be drained / rebooted

set -e
set -o nounset
set -o pipefail

CURRENTDATE=$(date +"%Y-%m-%d %T")

if [[ -z "${WORKER}" ]]; then
    echo "[Error] Variable WORKER cannot be blank."
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

    echo "Checking if \"${WORKER}\" is a worker node..."
    
    if (oc get nodes -l node-role.kubernetes.io/worker=,node-role.kubernetes.io/infra!= -oname | grep "${WORKER}") &> /dev/null; then
        echo "[OK] \"${WORKER}\" is a worker node. Proceeding with draining..."
        echo
    else
        echo "[Error] \"${WORKER}\" is not a worker node. Exiting script..."
        exit 1
    fi

}

## Function which drains the node bypassing the PDB check
drain_worker(){

    echo "Draining node \"${WORKER}\"..."
    oc adm drain "${WORKER}" --ignore-daemonsets --delete-emptydir-data --force --disable-eviction

    if [ $? -eq 0 ]; then 
        echo "[OK] Node \"${WORKER}\" drained successfully."
        echo
    else
        echo "[Error] Something went wrong."
        exit 1
    fi

}

## Function which reboot the node
reboot_worker(){

    echo "Rebooting node \"${WORKER}\"..."

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
    drain_worker
    reboot_worker
    check_reboot
    finish_job
}

main
