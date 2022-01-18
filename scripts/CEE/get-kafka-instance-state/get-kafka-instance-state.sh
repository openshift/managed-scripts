#!/bin/bash
set -o pipefail
set -o nounset

function main() {
  local timestamp
  timestamp=$(date +%s)
  local inspectDir
  inspectDir="inspect.${resource_namespace}.${timestamp}"
  mkdir "${inspectDir}"

  if ! oc get namespace "${resource_namespace}" &> /dev/null; then
      echo "No namespace found with name ${resource_namespace}" > "${inspectDir}"/failed.txt
      # Streaming tar.gz so that the output is in the expected format, even in this failure case
      tar zcf - ./"${inspectDir}"
      return 1
  fi

  local managedKafkaCR
  managedKafkaCR=$(oc -n "${resource_namespace}" get managedkafka -o name)
  local kafkaCR
  kafkaCR=$(oc -n "${resource_namespace}" get kafka -o name)
  local kafkaStatefulSet
  kafkaStatefulSet=$(oc -n "${resource_namespace}" get statefulset -l app.kubernetes.io/name=kafka -o name)

  inspectOps=(ns/"${resource_namespace}" "${managedKafkaCR}" "${kafkaCR}" --dest-dir "${inspectDir}")

  if [[ -v since ]]; then
      inspectOps+=("--since=${since}")
  elif [[ -v since_time ]]; then
      inspectOps+=("--since-time=${since_time}")
  fi

  oc -n "${resource_namespace}" adm inspect "${inspectOps[@]}" > "${inspectDir}"/ocadm.log 2>&1

  oc exec -n "${resource_namespace}" "${kafkaStatefulSet}" -c kafka -- sh /opt/kafka/bin/kafka-topics.sh \
    --bootstrap-server localhost:9096 --list > "${inspectDir}"/kafka-topics.txt 2>&1

  oc exec -n "${resource_namespace}" "${kafkaStatefulSet}" -c kafka -- sh /opt/kafka/bin/kafka-consumer-groups.sh \
    --bootstrap-server localhost:9096 --all-groups --describe  > "${inspectDir}"/kafka-consumer-groups.txt 2>&1

  oc exec -n "${resource_namespace}" "${kafkaStatefulSet}" -c kafka -- sh /opt/kafka/bin/kafka-acls.sh \
    --bootstrap-server localhost:9096 --list > "${inspectDir}"/kafka-acls.txt 2>&1

  find "${inspectDir}" -type f -name secrets.yaml -delete

  find "${inspectDir}" -path '*/managedkafkas/*' -name "*.yaml" -exec sed -i '/password:/d' {} \;

  tar zcf - ./"${inspectDir}"
}

main
