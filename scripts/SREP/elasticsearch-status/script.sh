#!/bin/bash

set -u
NAMESPACE=openshift-logging

if [ "$(oc whoami 2>/dev/null | wc -l | xargs echo)" == "0" ]; then
    echo "ERROR: You must be logged into an OCP/OSD cluster to run this script."
    exit 1
fi

## check operator subscriptions
echo -n "Cluster Logging Operator Subscription: "
if [ "$(oc -n $NAMESPACE get subscription cluster-logging --no-headers 2>/dev/null | wc -l | xargs echo)" == "0" ]; then
    echo "ERROR: No Cluster Logging Operator Subscription found."
    exit 1
fi
echo "Found"

echo -n "Elasticsearch Operator Subscription: "
if [ "$(oc -n $NAMESPACE get subscription elasticsearch-operator --no-headers 2>/dev/null | wc -l | xargs echo)" == "0" ]; then
    echo "ERROR: No Elasticsearch Operator Subscription found."
    exit 1
fi
echo "Found"

## check operator pods
echo -n "Cluster Logging Operator pods: "
if [ "$(oc -n $NAMESPACE get pods -l name=cluster-logging-operator --no-headers 2>/dev/null | grep -c Running | xargs echo)" == "0" ]; then
    echo "ERROR: No Cluster Logging Operator Pods found."
    exit 1
fi
echo "Running"

echo -n "Elasticsearch Operator pods: "
if [ "$(oc -n $NAMESPACE get pods -l name=elasticsearch-operator --no-headers 2>/dev/null | grep -c Running | xargs echo)" == "0" ]; then
    echo "ERROR: No Elasticsearch Operator Pods found."
    exit 1
fi
echo "Running"

## check operator CRs exist
echo -n "ClusterLogging CR: "
if [ "$(oc -n $NAMESPACE get clusterlogging --no-headers | wc -l | xargs echo)" == "0" ]; then
    echo "ERROR: No ClusterLogging CR found, logging must be installed"
    exit 1
fi
echo "Found"

echo -n "Elasticsearch configured in ClusterLogging CR: "
ES_REPLICAS=$(oc -n $NAMESPACE get clusterlogging -o json | jq -r '.items[].spec | select(.logStore != null) | select(.logStore.elasticsearch != null) | select(.logStore.elasticsearch.nodeCount != null) | .logStore.elasticsearch.nodeCount')
if [ "$ES_REPLICAS" == "0" ] || [ "$ES_REPLICAS" == "" ]; then
    echo "ERROR: Elasticsearch is not configured in the ClusterLogging CR"
    exit 1
fi
echo "Ok - Expected Replicas: $ES_REPLICAS"

echo -n "Checking ES CR exists: "
if [ "$(oc -n $NAMESPACE get elasticsearch elasticsearch -o jsonpath='{.spec.nodes[0].genUUID}' 2>/dev/null)" == "" ]; then
    echo "Error: Elasticsearch CR does not exist"
    exit 1
fi
echo "Found"

## check deployment/replicas
echo -n "Checking replicas count: "
ES_TOTAL_RS=$(oc -n $NAMESPACE get replicasets -l cluster-name=elasticsearch --no-headers 2>/dev/null | wc -l | xargs echo)
if [ "$ES_TOTAL_RS" == "0" ] || [ "$ES_TOTAL_RS" == "" ]; then
    echo "ERROR: Elasticsearch does not have any active replicasets"
    exit 1
elif [ "$ES_TOTAL_RS" != "$ES_REPLICAS" ]; then
    echo "WARN - found $ES_TOTAL_RS replica sets"
    oc -n $NAMESPACE get replicasets -l cluster-name=elasticsearch --no-headers 2>/dev/null
else
    echo "Ok - $ES_TOTAL_RS"
fi

echo -n "Check running pods matches replicas: "
if [ "$ES_REPLICAS" != "$(oc -n $NAMESPACE get replicasets -l cluster-name=elasticsearch -o json | jq -r '.items[] | select(.metadata.namespace | startswith("default") or startswith("kube") or startswith("openshift")) | select(.status.replicas > 0) | select(.status.replicas == .status.readyReplicas) | select(.status.replicas == .status.availableReplicas) | .status.replicas' | wc -l | xargs echo)" ]; then
    echo "Error: Running pods does not match replica count"
    exit 1
fi
echo "Ok"

echo -n "Checking ES deployment count: "
ES_DEPLOYMENT_TOTAL=$(oc -n $NAMESPACE get deployment --no-headers -l cluster-name=elasticsearch | wc -l | xargs echo)
if [ "$ES_DEPLOYMENT_TOTAL" == "0" ] || [ "$ES_DEPLOYMENT_TOTAL" == "" ]; then
    echo "ERROR: Elasticsearch does not have any active deployments"
    exit 1
elif [ "$ES_DEPLOYMENT_TOTAL" != "$ES_REPLICAS" ]; then
    echo "WARN - found $ES_TOTAL_RS deployments"
    oc -n $NAMESPACE get deployment --no-headers -l cluster-name=elasticsearch
else
    echo "Ok - $ES_DEPLOYMENT_TOTAL"
fi

echo -n "Current ES UUID: "
CURRENT_GENUUID=$(oc -n $NAMESPACE get elasticsearch elasticsearch -o jsonpath='{.spec.nodes[0].genUUID}')
if [ "$CURRENT_GENUUID" == "" ]; then
    echo "ERROR: Didn't find a value for old genUUID.  Check Elasticsearch CR:"
    echo "       oc -n $NAMESPACE get elasticsearch elasticsearch -o jsonpath='{.spec.nodes[0].genUUID}'"
    oc -n $NAMESPACE get elasticsearch elasticsearch -o jsonpath='{.spec.nodes[0].genUUID}'
    exit 1
fi
echo "Ok - $CURRENT_GENUUID"

echo -n "Current ES storage size: "
ES_STORAGE_SIZE=$(oc -n $NAMESPACE get clusterlogging -o json | jq -r ".items[] | .spec.logStore.elasticsearch.storage.size")
if [ "$ES_STORAGE_SIZE" == "0Gi" ] || [ "$ES_STORAGE_SIZE" == "" ]; then
    echo "ERROR: Elasticsearch ClusterLogging CR does not have any size set"
    exit 1
fi
echo "$ES_STORAGE_SIZE"

echo -n "Current logging-storage-quota: "
ES_LOGGING_STORAGE_QUOTA=$(oc -n $NAMESPACE get resourcequota logging-storage-quota -o json | jq -r ".spec.hard[\"requests.storage\"]")
echo "Ok - $ES_LOGGING_STORAGE_QUOTA"

echo "Listing PVCs in $NAMESPACE:"
oc -n $NAMESPACE get pvc --no-headers -o json | jq -r '.items[] | "{\"" + .metadata.name + "\",\"" + .spec.volumeName + "\"}"'
echo -n "Checking bound pvcs match UUID for ES :"
for pvc in $(oc -n $NAMESPACE get pvc -o jsonpath='{.items[?(@.status.phase=="Bound")].metadata.name}'); do
    if [ "$(echo "$pvc" | sed -n 's/^elasticsearch-elasticsearch-cdm-\([[:alnum:]]*\)-.*$/\1/p')" != "$CURRENT_GENUUID" ]; then
        echo "ERROR: $pvc does not match current UUID $CURRENT_GENUUID"
    fi
done
echo "Ok"

ES_POD=$(oc get po -n $NAMESPACE --no-headers -l component=elasticsearch | head -n1 | awk '{print $1}')
echo "Finding ES master: "
oc exec -n $NAMESPACE -c elasticsearch "$ES_POD" -- es_util --query=_cat/master?v
echo "Listing ES Nodes: "
oc exec -n $NAMESPACE -c elasticsearch "$ES_POD" -- es_util --query=_cat/nodes?v

echo "Elasticsearch Disk usage: "
for espod in $(oc -n $NAMESPACE get pods -l component=elasticsearch -o jsonpath='{.items[*].metadata.name}'); do
    echo "$espod"
    oc -n $NAMESPACE exec -c elasticsearch "$espod" -- df -H | grep /elasticsearch/persistent
done

echo  "Elasticsearch Health: "
oc exec -n $NAMESPACE -c elasticsearch "$ES_POD" -- health
echo -n "Elasticsearch Total project.* indices: "
oc exec -n $NAMESPACE -c elasticsearch "$ES_POD" -- es_util --query=_cat/indices | grep -c " project"
echo "Elasticsearch Top 10 Indices: "
for indice in $(oc exec -n $NAMESPACE -c elasticsearch "$ES_POD" -- es_util --query="_cat/indices?bytes=b\&s=store.size" | head -n 10 | tail -n +2 | awk '{print $3 "," $9 }'); do 
    name=${indice%%,*} 
    b=${indice#*,}
    echo -e "$name\t\t $(numfmt --to=iec-i --suffix=B --padding=7 "$b")"
done

echo "Elasticsearch Problem Indices: "
oc exec -n $NAMESPACE -c elasticsearch "$ES_POD" -- indices | grep "yellow"
echo "Elasticsearch Red Indices: "
oc exec -n $NAMESPACE -c elasticsearch "$ES_POD" -- indices | grep "red"
echo  "Elasticsearch Cluster Allocation: "
oc exec -n $NAMESPACE -c elasticsearch "$ES_POD" -- es_util --query=_cluster/allocation/explain?pretty
echo "Elasticsearch Catalog Allocation: "
oc exec -n $NAMESPACE -c elasticsearch "$ES_POD" -- es_util --query=_cat/allocation?bytes=b\&v
echo -n "Checking that Elasticsearch is in managed state: "
if [ "$(oc get clusterlogging instance -o json | jq '.spec.managementState')" != "\"Managed\"" ]; then
    echo "WARN: Elasticsearch is not in a managed state"
else
    echo "Ok"
fi

echo "Checking PVC labels"
oc get pvc -n $NAMESPACE -l logging-cluster=elasticsearch
echo "cluster logging csv is $(oc get sub cluster-logging -o json | jq '.status.installedCSV')"
echo "elasticsearch operator csv is $(oc get sub elasticsearch-operator -o json | jq '.status.installedCSV')"
echo -n "Checking fluentd pods are healthy: "
FLUENTD_POD_COUNT=$(oc -n $NAMESPACE get po -l component=fluentd --no-headers | grep -vc "Running" 2>/dev/null)
if [ "$FLUENTD_POD_COUNT" != "0" ]; then
    echo "Error: fluentd pods are not all in Running state."
    oc -n $NAMESPACE get po -l component=fluentd
    exit 1
fi
echo "Ok"

echo "Checking fluentd queue length: "
for POD in $(oc get po -n $NAMESPACE -l component=fluentd --no-headers -o name); do
    echo -n "$POD fluentd blocked action count: "
    oc logs -n $NAMESPACE "$POD" | grep -c 'action=:block'
done

echo "$NAMESPACE jobs: "
oc get jobs -n $NAMESPACE

echo "Seems things are not too bad."
echo "Have a cookie."

# list details of the incides
#index=${1}
#shard=${2:-0}
#primary=${3:-'false'}
#oc -n openshift-logging exec -c elasticsearch $pod -- es_util --query=_cluster/allocation/explain?pretty -d"{\"index\": \"$index\", \"shard\": $shard, \"primary\": $primary}"