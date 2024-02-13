#!/bin/bash

set -e
set -o nounset
set -o pipefail

CURRENTDATE=$(date +"%Y-%m-%d %T")

## validate input
if [[ -z "${MASTER}" ]]; then
    echo "Variable MASTER cannot be blank"
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


## Function for MASTER node validation
check_master(){

    echo "Checking if \"${MASTER}\" is a master node..."
    
    if (oc get nodes -l node-role.kubernetes.io/master= -oname | grep "${MASTER}") &> /dev/null; then
        echo "[OK] \"${MASTER}\" is a master node."
        echo
    else
        echo "[Error] \"${MASTER}\" is not a master node."
        exit 1
    fi

}

## Function for kubelet restart
restart_kubelet(){

    echo "Restarting Kubelet on \"${MASTER}\"..."
    cat <<EOF | oc -n default debug node/${MASTER}
    chroot /host 
    systemctl restart kubelet
EOF

    if [ $? -eq 0 ]; then 
        echo "[SUCCESS] Kubelet successfully restarted on \"${MASTER}\" ."
        echo
    else
        echo "[Error] Something is fishy."
        exit 1
    fi

}



main(){
    start_job
    check_master
    restart_kubelet
    finish_job
}

main
