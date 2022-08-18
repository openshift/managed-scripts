#!/bin/bash
set -o pipefail
set -o nounset

function main() {
    local service
    service=$(oc -n "${resource_namespace}" get service  -o name -l "app.kubernetes.io/name=kafka" | grep bootstrap | head -n1)
    
    oc exec -n "${resource_namespace}" "${service}" -c kafka -- \
       ./bin/kafka-transactions.sh --bootstrap-server localhost:9096 describe --transactional-id "${transactional_id}"
}

main
