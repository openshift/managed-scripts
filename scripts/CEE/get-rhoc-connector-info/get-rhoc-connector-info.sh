#!/bin/bash

timestamp=$(date +%s)
outputDir="inspect.${connector_id}.${timestamp}"

mkdir "${outputDir}"

set -o pipefail
set -o nounset

# Collecting resources for connector ${connector_id}
oc get \
    ManagedConnector,KameletBinding,Integration,IntegrationKit,KafkaConnect,KafkaConnector,Deployment,ReplicaSet,Pod,PodDisruptionBudget,NetworkPolicy,ConfigMap,Service,EndpointSlice \
    -l cos.bf2.org/connector.id="${connector_id}" \
    --all-namespaces \
    -o yaml &> "${outputDir}/resources.yaml"

NAMESPACED_NAMES=$(oc get pods --selector=cos.bf2.org/connector.id="${connector_id}" --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{";"}{.metadata.name}{" "}{end}' 2> "${outputDir}"/collect-namespaces.log)
NAMESPACE=""

for NAMESPACED_NAME in $NAMESPACED_NAMES; do
    NAMESPACE=$(echo "${NAMESPACED_NAME}"| cut -d ";" -f 1)
    POD=$(echo "${NAMESPACED_NAME}"| cut -d ";" -f 2)

    if [ -z "${nologs+x}" ]; then
        # Collecting logs for pod ${POD} in namespace ${NAMESPACE}
        oc logs "${POD}" --namespace "${NAMESPACE}" | sed -e 's/\x1b\[[0-9;]*m//g' &> "${outputDir}/log-${NAMESPACE}-${POD}.txt"
    fi
done

# Collecting events for namespace ${NAMESPACE}
oc get events --namespace "${NAMESPACE}" -o yaml &> "${outputDir}/events-${NAMESPACE}.yaml"

# collect events in text format as well
oc get events --namespace "${NAMESPACE}" &> "${outputDir}/events-${NAMESPACE}.txt"

# tar up all collected data to stdout
# users can collect the data by running
# kubectl -n openshift-backplane-managed-scripts logs <job-id> | tar xzf - 
tar zcf - ./"${outputDir}"
