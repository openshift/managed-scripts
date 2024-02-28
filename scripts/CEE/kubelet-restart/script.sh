#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

CURRENTDATE=$(date +"%Y-%m-%d %T")

## validate input
if [[ -z "${NODE}" ]]; then
    echo "Variable NODE cannot be blank"
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



## Function for kubelet restart
restart_kubelet(){

    echo "Restarting Kubelet on \"${NODE}\"..."
    cat <<EOF | oc -n default debug node/${NODE}
    chroot /host 
    systemctl restart kubelet
EOF

    if [ $? -eq 0 ]; then 
        echo "[SUCCESS] Kubelet successfully restarted on \"${NODE}\" ."
        echo
    else
        echo "[Error] Something is fishy."
        exit 1
    fi

}



main(){
    start_job
    restart_kubelet
    finish_job
}

main
