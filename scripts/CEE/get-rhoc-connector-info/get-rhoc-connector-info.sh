#!/bin/bash

timestamp=$(date +%s)
outputDir="inspect.${connector_id}.${timestamp}"

mkdir "${outputDir}"

set -o pipefail
set -o nounset

echo "Collecting resources for connector ${connector_id}"         

oc get \
    ManagedConnector,KameletBinding,Integration,IntegrationKit,KafkaConnect,KafkaConnector,Deployment,ReplicaSet,Pod,PodDisruptionBudget,NetworkPolicy,ConfigMap,Service,EndpointSlice \
    -l cos.bf2.org/connector.id="${connector_id}" \
    --all-namespaces \
    -o yaml > ${outputDir}/resources.yaml
       
PODS=$(oc get pods --selector=cos.bf2.org/connector.id="${connector_id}" --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{";"}{.metadata.name}{" "}{end}')
NAMESPACE=""

for POD in $PODS; do
    ITEMS=(${POD//;/ })
    NAMESPACE="${ITEMS[0]}"

    if [ -z ${nologs+x} ]; then
        echo "Collecting logs for pod ${ITEMS[1]} in namespace ${ITEMS[0]}"         
        oc logs ${ITEMS[1]} --namespace ${ITEMS[0]} | sed -e 's/\x1b\[[0-9;]*m//g' > ${outputDir}/log-${ITEMS[0]}-${ITEMS[1]}.txt
    fi
done

echo "Collecting events for namespace ${NAMESPACE}"         

oc get events --namespace ${NAMESPACE} -o yaml > ${outputDir}/events-${NAMESPACE}.yaml
