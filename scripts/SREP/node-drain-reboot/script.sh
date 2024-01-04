#!/bin/bash

set -e
set -o nounset
set -o pipefail

validate_input() {
    echo 'VALIDATING INPUT CHECKING IF CORRECT NODE IS PROVIDED..'
    if [[ -z "$node" ]]; then
        echo 'Variable nodes cannot be blank'
        exit 1
    fi
    echo "NODE $node IS PROVIDED..."
    oc get node "$node"
}

drain_nodes() {
    echo 'DRAINING NODE..'
    oc adm cordon "$node"
    oc adm drain "$node" --ignore-daemonsets --delete-emptydir-data --force
    if ! oc adm drain "$node" --ignore-daemonsets --delete-emptydir-data --force 2>&1 | grep -q "PodDisruptionBudget"; then
        echo "NODE SUCCESSFULLY DRAINED"
    else
        echo "POD DISRUPTION BUDGET ERROR OCCURED"
    fi
}

reboot_nodes() {
    echo 'REBOOTING NODE..'
    oc -n default debug node/"$node" -- chroot /host reboot &
}

verify_ready() {
    echo 'VERIFYING IF NODES ARE NOW IN READY STATE..'
    while [[ "$(oc get node "$node" | awk '{print $2}')" == *"NotReady"* ]];
    do
        oc get node "$node"
        echo 'NODES ARE NOT READY YET...'
    done
    echo 'NODES ARE NOW READY. UNCORDING..'
    oc adm uncordon "$node"
}

main() {
  validate_input
  drain_nodes
  reboot_nodes
  verify_ready
  echo "Succeed."
  exit 0
}

main "$@"
