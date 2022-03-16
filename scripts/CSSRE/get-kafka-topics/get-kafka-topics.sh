#!/bin/bash

usage="Usage: $0 -n KAFKA_NAMESPACE [-t TOPIC] [-f <under-replicated-partitions|under-min-isr-partitions|unavailable-partitions>]"

while getopts ":n:t:f:" opt; do
  case $opt in
    n) kafka_namespace="${OPTARG}"
    ;;
    t) topic="${OPTARG}"
    ;;
    f) filter="${OPTARG}"
    ;;
    \?)
    echo "$usage"
    exit 1
    ;;
    :) echo "Option -$OPTARG requires an argument" >&2
    exit 1
  esac
done

if [ -z "$kafka_namespace" ]; then
  echo -e "Namespace required\n$usage" >&2
  exit 1
fi

if [ "$filter" != "" ] && [ "${filter}" != "under-replicated-partitions" ] && [ "$filter" != "under-min-isr-partitions" ] && [ "$filter" != "unavailable-partitions" ]; then
  echo -e "Invalid filter\n$usage" >&2
  exit 1
else 
  filter="--$filter"
fi

echo "Namespace: $kafka_namespace"
echo "Topic: $topic"
echo -e "Filter: $filter\n"

function main() {
  echo "Getting kafka topics"
  
  kafka_cluster=$(oc -n "$kafka_namespace" get kafka --no-headers | awk '{print $1}')
  echo "Kafka cluster: ${kafka_cluster}"

  if [ -z "$topic" ]; then
    oc -n "$kafka_namespace" exec -it statefulset/"$kafka_cluster"-kafka -c kafka -- env - bin/kafka-topics.sh --bootstrap-server localhost:9096 --describe "$filter"
  else
    oc -n "$kafka_namespace" exec -it statefulset/"$kafka_cluster"-kafka -c kafka -- env - bin/kafka-topics.sh --bootstrap-server localhost:9096 --describe --topic "$topic" "$filter"
  fi
}

main