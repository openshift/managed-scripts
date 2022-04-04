#!/bin/bash

set -o pipefail
set -o nounset

function main(){

  local deploymentCount
  local statefulsetCount
  local kafkaBrokerRequired
  local kafkaBrokerCount
  local zookeeperBrokerRequired
  local zookeeperBrokerCount
  local adminServerRequired
  local adminServerCount
  local canaryRequired
  local canaryCount
  local kafkaExporterRequired
  local kafkaExporterCount
  local podCount
  local podRequired
  local podFailCount
  local serviceCount
  local routeCount
  local pvCount
  local pvcCount
  local secretCount
  local configmapCount
  local totalCount

  podFailCount=0
  
  echo "_______________________________________________________________"
  echo " Kafka Resource Status" 
  echo "_______________________________________________________________"

  echo "_______________________________________________________________"
  echo " Deployment/Statefulset Status" 
  echo "_______________________________________________________________"
 
  deploymentCount=$(oc get deployments -n "${resource_namespace}" | tail -n +2 | wc -l | sed 's/^ *//g')
  echo "Deployment(s) $deploymentCount" > kafka-deployment-statefulsets.txt
 
  statefulsetCount=$(oc get statefulsets -n "${resource_namespace}" | tail -n +2 | wc -l | sed 's/^ *//g')
  echo "Statefulset(s) $statefulsetCount" >> kafka-deployment-statefulsets.txt

  cat < kafka-deployment-statefulsets.txt | column -t

  echo "_______________________________________________________________"
  echo " Component Status" 
  echo "_______________________________________________________________"

  
  kafkaBrokerRequired=$(oc get statefulset "${resource_cluster_name}"-kafka -n "${resource_namespace}" -ojson | jq '.spec.replicas')
  kafkaBrokerCount=$(oc get statefulset "${resource_cluster_name}"-kafka -n "${resource_namespace}" -ojson | jq '.status.readyReplicas')  
  echo "Kafka-Brokers $kafkaBrokerCount/$kafkaBrokerRequired ok" > kafka-pods.txt
  if [ "$kafkaBrokerRequired" -ne "$kafkaBrokerCount" ]; then
    podFailCount=$((podFailCount+1))
  fi
 
  zookeeperBrokerRequired=$(oc get statefulset "${resource_cluster_name}"-zookeeper -n "${resource_namespace}" -ojson | jq '.spec.replicas')
  zookeeperBrokerCount=$(oc get statefulset "${resource_cluster_name}"-zookeeper -n "${resource_namespace}" -ojson | jq '.status.readyReplicas')  
  echo "Zookeeper-Brokers $zookeeperBrokerCount/$zookeeperBrokerRequired ok" >> kafka-pods.txt
  if [ "$zookeeperBrokerRequired" -ne "$zookeeperBrokerCount" ]; then
    podFailCount=$((podFailCount+1))
  fi

  adminServerRequired=$(oc get deployment "${resource_cluster_name}"-admin-server -n "${resource_namespace}" -ojson | jq '.spec.replicas')
  adminServerCount=$(oc get deployment "${resource_cluster_name}"-admin-server -n "${resource_namespace}" -ojson | jq '.status.readyReplicas')
  echo "Admin-Server(s) $adminServerCount/$adminServerRequired ok" >> kafka-pods.txt
  if [ "$adminServerRequired" -ne "$adminServerCount" ]; then
    podFailCount=$((podFailCount+1))
  fi

  canaryRequired=$(oc get deployment "${resource_cluster_name}"-canary -n "${resource_namespace}" -ojson | jq '.spec.replicas')
  canaryCount=$(oc get deployment "${resource_cluster_name}"-canary -n "${resource_namespace}" -ojson | jq '.status.readyReplicas')
  echo "Canary(s) $canaryCount/$canaryRequired ok" >> kafka-pods.txt
  if [ "$canaryRequired" -ne "$canaryCount" ]; then
    podFailCount=$((podFailCount+1))
  fi

  kafkaExporterRequired=$(oc get deployment "${resource_cluster_name}"-kafka-exporter -n "${resource_namespace}" -ojson | jq '.spec.replicas')
  kafkaExporterCount=$(oc get deployment "${resource_cluster_name}"-kafka-exporter -n "${resource_namespace}" -ojson | jq '.status.readyReplicas')
  echo "Kafka-Exporter(s) $kafkaExporterCount/$kafkaExporterRequired ok" >> kafka-pods.txt
  if [ "$kafkaExporterRequired" -ne "$kafkaExporterCount" ]; then
    podFailCount=$((podFailCount+1))
  fi

  podCount=$(oc get pods -n "${resource_namespace}" | grep -c 1/1 | sed 's/^ *//g')
  podRequired=$((kafkaBrokerRequired + zookeeperBrokerRequired + adminServerRequired + canaryRequired + kafkaExporterRequired))
  echo "---" >> kafka-pods.txt
  echo "Pod(s)-Running $podCount/$podRequired ok" >> kafka-pods.txt
  if [ "$podCount" -ne "$podRequired" ]; then
    podFailCount=$((podFailCount+1))
  fi

  cat < kafka-pods.txt | column -t

  echo "_______________________________________________________________"
  echo " Gathering Logs for Unfiltered Kafka Broker Data" 
  echo "_______________________________________________________________"

  if [ "$kafkaBrokerCount" -ne 0 ]; then
    for (( i=0; i<=kafkaBrokerCount-1; i++))
    do
        oc logs "${resource_cluster_name}"-kafka-"$i" -n "${resource_namespace}" --tail 1000 | egrep -v '.*INFO.*$|.*TRACE.*$' > kafka-"$i".txt
        echo "kafka-$i.txt created"
    done
  fi

  echo "_______________________________________________________________"
  echo " Cluster Events" 
  echo "_______________________________________________________________"

  oc get events -n "${resource_namespace}" | egrep -v '.*Normal.*$' > kafka-events.txt
  echo "kafka-events.txt created"

  echo "_______________________________________________________________"
  echo " Networking Status" 
  echo "_______________________________________________________________"
 
  serviceCount=$(oc get services -n "${resource_namespace}" | tail -n +2 | wc -l | sed 's/^ *//g')
  echo "Service(s) $serviceCount" > kafka-services.txt

  routeCount=$(oc get routes -n "${resource_namespace}" | tail -n +2 | wc -l | sed 's/^ *//g')
  echo "Route(s) $routeCount" >> kafka-services.txt

  cat < kafka-services.txt | column -t

  echo "_______________________________________________________________"
  echo " Checking Network Status for Availability" 
  echo "_______________________________________________________________"
 
  oc run -q --env brokerCount="$kafkaBrokerCount" "$resource_cluster_name" --image=registry.redhat.io/rhel7/rhel-tools -i --restart=Never --rm -- <test-endpoint.sh 2>/dev/null | column -t

  echo "_______________________________________________________________"
  echo " Storage Status" 
  echo "_______________________________________________________________"
 
  pvCount=$(oc get pv | grep "${resource_namespace}" | grep -c Bound | sed 's/^ *//g')
  echo "Persistent-Volume(s) $pvCount bound" > kafka-volumes.txt

  pvcCount=$(oc get pvc -n "${resource_namespace}" | grep -c Bound | sed 's/^ *//g')
  echo "Persistent-Volume-Count $pvcCount bound" >> kafka-volumes.txt

  cat < kafka-volumes.txt | column -t

  echo "_______________________________________________________________"
  echo " Secrets" 
  echo "_______________________________________________________________"
 
  secretCount=$(oc get secrets -n "${resource_namespace}" | tail -n +2 | wc -l | sed 's/^ *//g')
  echo "Secret(s) $secretCount"

  echo "_______________________________________________________________"
  echo " ConfigMaps" 
  echo "_______________________________________________________________"
 
  configmapCount=$(oc get configmaps -n "${resource_namespace}" | tail -n +2 | wc -l | sed 's/^ *//g')
  echo "Configmap(s) $configmapCount"

  echo "_______________________________________________________________"
  echo " Kafka Cluster Items in order by AGE" 
  echo "_______________________________________________________________"

  { echo "-------------------------DEPLOYMENTS-----------------------------";
  oc get deployments -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp;
  echo "";
  echo "-------------------------STATEFULSETS-----------------------------";
  oc get statefulsets -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp;
  echo "";
  echo "-------------------------PODS-----------------------------";
  oc get pods -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp;
  echo "";
  echo "-------------------------SERVICES-----------------------------";
  oc get services -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp;
  echo "";
  echo "-------------------------ROUTES-----------------------------";
  oc get routes -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp;
  echo "";
  echo "-------------------------PERSISTENT VOLUMES-----------------------------";
  oc get pv --sort-by=.metadata.creationTimestamp | grep "${resource_namespace}";
  echo "";
  echo "-------------------------PERSISTENT VOLUME CLAIMS-----------------------------";
  oc get pvc -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp;
  echo "";
  echo "-------------------------SECRETS-----------------------------";
  oc get secrets -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp;
  echo "";
  echo "-------------------------CONFIGMAPS-----------------------------";
  oc get configmaps -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp; } > kafka-age.txt

  echo "kafka-status-age.txt created"

  totalCount=$((podCount + serviceCount + pvCount + pvcCount + deploymentCount + kafkaBrokerCount + zookeeperBrokerCount))
 
  echo "_______________________________________________________________"
  echo " Total Resources check $totalCount"
  { echo "Pod(s) $podCount/$podRequired"; echo "Service(s) $serviceCount"; echo "Route(s) $routeCount"; echo "PV(s) $pvCount";  
    echo "PVC $pvcCount"; echo "Secret(s) $secretCount"; echo "Configmap(s) $configmapCount";
  } > kafka-total-resources.txt
  cat < kafka-total-resources.txt | column -t
  echo "_______________________________________________________________"

  if [[ $podFailCount -ne 0 ]]; then
    echo "_______________________________________________________________"
    echo " FAILURES"
    echo "Pod-Failure(s) $podFailCount Total-Pod(s) $podCount/$podRequired" | column -t
  fi

}

main
