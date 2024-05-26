#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

if [ -z "${CLUSTER_ID}" ]; then
    echo "variable CLUSTER_ID cannot be blank"
    exit 1
fi

if [[ $(oc get namespace --no-headers -o custom-columns=":metadata.name" | grep -c "${CLUSTER_ID}-") != 1 ]]; then
    echo "unable to find namespaces for cluster ID ${CLUSTER_ID} -- please ensure you are on the correct management cluster"
    exit 1
fi

NAMESPACE=$(oc get namespace --no-headers -o custom-columns=":metadata.name" | grep "${CLUSTER_ID}-")

BROKEN_MACHINES=$(oc -n "${NAMESPACE}" get machines.cluster.x-k8s.io -ojson | jq -r '.items[] | select(.status.phase!="Running") | .metadata.name')

for broken_machine in ${BROKEN_MACHINES}; do
    echo "--- Remediating machine ${broken_machine} in namespace ${NAMESPACE} ---"
    secret_name=$(oc -n "${NAMESPACE}" get "machines.cluster.x-k8s.io/${broken_machine}" -ojson | jq -r '.spec.bootstrap.dataSecretName | sub("user-data";"token")')
    awsmachine_name=$(oc -n "${NAMESPACE}" get "machines.cluster.x-k8s.io/${broken_machine}" -ojson | jq -r '.spec.infrastructureRef.name')
    oc -n "${NAMESPACE}" delete "secret/${secret_name}"
    oc -n "${NAMESPACE}" delete "awsmachines.infrastructure.cluster.x-k8s.io/${awsmachine_name}"
    oc -n "${NAMESPACE}" delete "machines.cluster.x-k8s.io/${broken_machine}" --ignore-not-found # sometimes this machine is already gone by the time the awsmachine deletion completes, but that's okay
done

echo "--- Remediation Complete ---"
