#!/bin/bash

usage="Usage: $0 -n KAFKA_NAMESPACE [-s statefulset| -p pod]"

while getopts ":n:s:p:" opt; do
  case $opt in
    n) kafka_namespace="${OPTARG}"
    ;;
    s) statefulset="${OPTARG}"
    ;;
    p) pod="${OPTARG}"
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


echo "Namespace: $kafka_namespace"
echo "Statefulset: $statefulset"
echo "Pod: $pod"


function main() {
  echo "Annotating brokers"
  
  kafka_cluster=$(oc -n "$kafka_namespace" get kafka --no-headers | awk '{print $1}')
  # kafka_cluster="testing"
  echo "Kafka cluster: ${kafka_cluster}"
  
  if [ -z $pod ]; then
   if [ -z "$statefulset" ]; then
    echo -e "You must specify either a statefulset or a pod.\n$usage"
   elif [[ "$statefulset" == "kafka" ]]; then
    oc -n "$kafka_namespace" annotate statefulset/"$kafka_cluster"-kafka strimzi.io/manual-rolling-update=true
   elif [[ "$statefulset" == "zookeeper" ]]; then
    oc -n "$kafka_namespace" annotate statefulset/"$kafka_cluster"-zookeeper strimzi.io/manual-rolling-update=true
   else
    echo -e "No valid input found.\n$usage"  
    fi
  else
    if [ -z "$statefulset" ]; then
     oc -n "$kafka_namespace" annotate pod "$pod" strimzi.io/manual-rolling-update=true
    else
      echo -e "You must specify either a stateful set or a pod, but not both.\n$usage"
    fi
  fi

}

main

