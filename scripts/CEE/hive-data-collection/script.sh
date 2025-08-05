#!/bin/bash
#
# Collect data from Hive clusters in order to troubleshoot/debug cluster provisioning delays.
# Input:
#  (Env) CLUSTERID
#        Description: The Internal Cluster ID for which data is being collected

set -e
set -o nounset
set -o pipefail

start_job(){
    echo "Job started at $(date +"%Y-%m-%d %T")"
    echo ".................................."
    echo
}

finish_job(){
    echo
    echo ".................................."
    echo "Job finished at $(date +"%Y-%m-%d %T")"
}

CLUSTER_NAMESPACE="uhc-production-${CLUSTER_ID}"

if ! oc get namespace "${CLUSTER_NAMESPACE}" &>/dev/null; then
    echo "Namespace ${CLUSTER_NAMESPACE} does not exist. Please check the CLUSTER_ID."
    exit 1
fi

## Function which checks the clusterdeployment status
## and print the details of each clusterdeployment
read_clusterdeployment(){
       
    echo "### Checking clusterdeployment status..."
    echo
    oc get clusterdeployment -n "${CLUSTER_NAMESPACE}"
    echo
    oc get clusterdeployment -n "${CLUSTER_NAMESPACE}" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | sort -u | while read -r cluster; do
        echo "### ClusterDeployment: ${cluster}"
        echo "------------------------------------------------------------------"
        echo
        oc get clusterdeployment "${cluster}" -n "${CLUSTER_NAMESPACE}" -o yaml
        echo
    done 
}

## Function which checks pods status
## and print the details of each pod
read_pods(){

    echo "### Checking pods status..."
    echo
    oc get pods -n "${CLUSTER_NAMESPACE}" -o wide
    echo
    oc get pods -n "${CLUSTER_NAMESPACE}" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | sort -u | while read -r pod; do
        echo "### Pod: ${pod}"
        echo "------------------------------------------------------------------"
        echo
        oc describe pod "${pod}" -n "${CLUSTER_NAMESPACE}"
        echo
    done
}

## Function which checks the logs of each pod
read_pods-logs(){
    
    echo "### Checking pods logs..."
    echo
    oc get pods -n "${CLUSTER_NAMESPACE}" -o wide
    echo
    oc get pods -n "${CLUSTER_NAMESPACE}" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | sort -u | while read -r pod; do
        echo "### Pod: ${pod}"
        echo "------------------------------------------------------------------"
        echo
        oc logs "${pod}" -n "${CLUSTER_NAMESPACE}"
        echo
    done
}

## Function which checks the clustersync status
## and print the details of each clustersync
read_clustersync(){

    echo "### Checking clustersync status..."
    echo
    oc get clustersync -n "${CLUSTER_NAMESPACE}"
    echo
    oc get clustersync -n "${CLUSTER_NAMESPACE}" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | sort -u | while read -r sync; do
        echo "### ClusterSync: ${sync}"
        echo "------------------------------------------------------------------"
        echo
        oc describe clustersync "${sync}" -n "${CLUSTER_NAMESPACE}"
        echo
    done

}

## Function which checks the events in the namespace
read_events(){

    echo "### Checking events..."
    echo
    oc get events -n "${CLUSTER_NAMESPACE}" --sort-by='.metadata.creationTimestamp'
    echo
}

main(){
    start_job
    case "${ACTION}" in
        "full")
            read_clusterdeployment
            read_pods
            read_pods-logs
            read_clustersync
            read_events
            ;;
        "pods")
            read_pods
            read_pods-logs
            ;;
        "clusterdeployment")
            read_clusterdeployment
            ;;
        "clustersync")
            read_clustersync
            ;;
        "events")
            read_events
            ;;
        *)
            echo "Invalid action specified. Please use 'full', 'pods', 'clusterdeployment', 'clustersync', or 'events'."
            exit 1
            ;;
    esac
    finish_job
}

main
