#!/bin/bash
#
# Description: Prints out the complete health check for etcd with recent logs incase of unhealthy clusters

set -uo pipefail

readonly LOG_INFO="INFO:"
readonly LOG_ERROR="ERROR:"

ETCD_POD=$(oc get pods -l k8s-app=etcd -n openshift-etcd -o jsonpath='{.items[*].metadata.name}' | awk '{ print $1 }')
ETCD_SUMMARY=$(oc get etcd -o=jsonpath='{range .items[0].status.conditions[?(@.type=="EtcdMembersAvailable")]}{.message}{"\n"}')

readonly ETCD_POD
readonly ETCD_SUMMARY

# Get a list of etcd members and a one line summary
get_etcd_summary(){
    echo
    echo "$LOG_INFO etcdctl member list"
    oc exec "$ETCD_POD" -n openshift-etcd -c etcdctl -- sh -c "etcdctl member list -w table"

    echo
    echo "$LOG_INFO summary of etcd"
    echo "$ETCD_SUMMARY"
}

## Print out the summary of Endpoint Status and Health
get_endpoint_summary(){
    echo
    echo "$LOG_INFO etcdctl endpoint status"
    { endpoint_status=$(oc exec "$ETCD_POD" -n openshift-etcd -c etcdctl -- sh -c "etcdctl endpoint status -w table" 2>&1 1>&3-) ;} 3>&1
    echo
    echo "$endpoint_status" 

    echo
    echo "$LOG_INFO etcdctl endpoint health"
    { endpoint_health=$(oc exec "$ETCD_POD" -n openshift-etcd -c etcdctl -- sh -c "etcdctl endpoint health -w table" 2>&1 1>&3-) ;} 3>&1
    echo
    echo "$endpoint_health"
}


# Get the logs for the unhealthy node(s)
get_logs(){
    echo "$ETCD_SUMMARY" | sed -n 1'p' | tr ',' '\n' | grep unhealthy  |  while read -r word; do
        name=$(echo "$word" | awk '{ print $1 }')
        echo
        echo "$LOG_INFO logs for $name"
        echo   
        if command=$(oc logs -c etcd -n openshift-etcd etcd-"$name")
        then
            echo "$command"
        elif cmd=$(oc get nodes -l node-role.kubernetes.io/master="" -o name | awk '{print $1}' | sed 1q |
            while IFS= read -r nodename; 
                do 
                    echo $'\nUsing crictl to fetch logs\n'
                    oc -n default debug "$nodename" -- sh -c 'chroot /host crictl ps -aql --label "io.kubernetes.container.name=etcd" | chroot /host xargs crictl logs --since 48h'; 
                done        
            )
        then
            echo "$cmd"
        else 
            echo "$LOG_ERROR The logs cannot be retreived. Please investigate manually"
        fi
    done
}

main(){
    get_etcd_summary
    get_endpoint_summary
    get_logs
    exit 0
}

main "$@"