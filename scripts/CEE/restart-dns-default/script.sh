#!/bin/bash

set -e
set -o errexit
set -o nounset
set -o pipefail

CURRENTDATE=$(date +"%Y-%m-%d %T")

## validate input
if [[ -z "${NAMESPACE}" ]]; then
    echo "Variable NAMESPACE cannot be blank"
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



## Function for daemonsent rollout start
restart_dns_pods(){

    echo -e "\nRestarting dns_pods in \"${NAMESPACE}\" namespace. Wait until rollout reaches 5 out 5"
    
     if oc -n openshift-dns rollout restart ds/dns-default 
     then
        echo -e "\n[SUCCESS] Pods rollout started in \"${NAMESPACE}\" ."
     else
        echo -e "\n[Error] Pods rollout has failed."
        exit 1
     fi

}


## Function for daemonset rollout status
monitor_dns_pods_restar_progress(){

    echo -e "\nRestarting dns_pods in \"${NAMESPACE}\"..."

    if   oc -n openshift-dns rollout status ds/dns-default 
    then
        echo -e "\n[SUCCESS] Pods rollout is completed successfully in \"${NAMESPACE}\" namespace.\n"
       
    else
        echo -e "\n[Error] Pods rollout has failed."
        exit 1
    fi

}

verify_dns_pods_are_ready(){

echo -e "\nVerifying that pods are in Running state..."

sleep 30

if [[ $(oc wait pods -n openshift-dns -l dns.operator.openshift.io/daemonset-dns=default --for=condition=Ready) ]]; then
        
        sleep 30	
	echo -e "\nAll pods are in the Running state\n";
	oc get pods -n openshift-dns -l dns.operator.openshift.io/daemonset-dns=default
	exit 1
fi


}


main(){
    start_job
    restart_dns_pods
    monitor_dns_pods_restar_progress
    verify_dns_pods_are_ready
    finish_job
}

main
