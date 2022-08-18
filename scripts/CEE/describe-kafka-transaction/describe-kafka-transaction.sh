#!/bin/bash
set -o pipefail
set -o nounset

function main() {
    local kafkaStatefulSet
    kafkaStatefulSet=$(oc -n "${resource_namespace}" get statefulset -l app.kubernetes.io/name=kafka -o name)

    oc exec -n "${resource_namespace}" "${kafkaStatefulSet}" -c kafka -- \
       ./bin/kafka-transactions.sh --bootstrap-server localhost:9096 describe --transactional-id "${transactional_id}"
}

main
