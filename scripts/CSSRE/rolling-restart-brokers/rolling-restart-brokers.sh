#!/bin/bash

usage="Usage: $0 -n KAFKA_NAMESPACE [-s statefulset/strimzipodset| -p pod]"

while getopts ":n:s:p:" opt; do
  case $opt in
    n) kafka_namespace="${OPTARG}"
    ;;
    s) s_set="${OPTARG}"
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
echo "Statefulset/Strimzipodset: $s_set"
echo "Pod: $pod"



function main() {
  
  echo "Checking strimzipodset enablement"

  strimzipodset_enabled=$(oc get pods -n "$kafka_namespace" --show-labels | grep -o "strimzi.io/controller=strimzipodset" | head -1)
  
  echo Strimzi Controller set to: "$strimzipodset_enabled"

  echo "Annotating brokers"
  
  kafka_cluster=$(oc -n "$kafka_namespace" get kafka --no-headers | awk '{print $1}')
  # kafka_cluster="testing"
  echo "Kafka cluster: ${kafka_cluster}"
  
  if [ -z "$pod" ]; then
   if [ -z "$s_set" ]; then
    echo -e "You must specify either a statefulset, strimzipodset or a pod.\n$usage"
   elif [[ "$s_set" == "kafka" ]] && [ "$strimzipodset_enabled" == "strimzi.io/controller=strimzipodset" ]; then
    oc -n "$kafka_namespace" annotate strimzipodset/"$kafka_cluster"-kafka strimzi.io/manual-rolling-update=true
   elif [[ "$s_set" == "kafka" ]] && [ -z "$strimzipodset_enabled" ]; then
    oc -n "$kafka_namespace" annotate statefulset/"$kafka_cluster"-kafka strimzi.io/manual-rolling-update=true
   elif [[ "$s_set" == "zookeeper" ]] && [ "$strimzipodset_enabled" == "strimzi.io/controller=strimzipodset" ]; then
    oc -n "$kafka_namespace" annotate strimzipodset/"$kafka_cluster"-zookeeper strimzi.io/manual-rolling-update=true
   elif [[ "$s_set" == "zookeeper" ]] && [ -z "$strimzipodset_enabled" ]; then
    oc -n "$kafka_namespace" annotate statefulset/"$kafka_cluster"-zookeeper strimzi.io/manual-rolling-update=true
   else
    echo -e "No valid input found.\n$usage"  
    fi
  else
    if [ -z "$s_set" ]; then
     oc -n "$kafka_namespace" annotate pod "$pod" strimzi.io/manual-rolling-update=true
    else
      echo -e "You must specify one of a statefulset/strimzipodset or a pod, but not both.\n$usage"
    fi
  fi

}

main

