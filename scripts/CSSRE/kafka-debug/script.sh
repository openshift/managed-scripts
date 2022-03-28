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
  
  printf "_______________________________________________________________  \n"
  printf " Kafka Resource Status\n" 
  printf "_______________________________________________________________  \n"

  printf "_______________________________________________________________  \n"
  printf " Deployment/Statefulset Status\n" 
  printf "_______________________________________________________________  \n"
 
  deploymentCount=$(oc get deployments -n "${resource_namespace}" | tail -n +2 | wc -l | sed 's/^ *//g')
  echo "Deployment(s) $deploymentCount" > kafka-deployment-statefulsets.txt
 
  statefulsetCount=$(oc get statefulsets -n "${resource_namespace}" | tail -n +2 | wc -l | sed 's/^ *//g')
  echo "Statefulset(s) $statefulsetCount" >> kafka-deployment-statefulsets.txt

  cat kafka-deployment-statefulsets.txt | column -t

  printf "_______________________________________________________________  \n"
  printf " Component Status\n" 
  printf "_______________________________________________________________  \n"

  
  kafkaBrokerRequired=$(oc get statefulset "${resource_cluster_name}"-kafka -n "${resource_namespace}" -ojson | jq '.spec.replicas')
  kafkaBrokerCount=$(oc get statefulset "${resource_cluster_name}"-kafka -n "${resource_namespace}" -ojson | jq '.status.readyReplicas')  
  echo "Kafka-Brokers $kafkaBrokerCount/$kafkaBrokerRequired ok" > kafka-pods.txt
  if [ $kafkaBrokerRequired -ne $kafkaBrokerCount ]; then
    (($podFailCount=$podFailCount+1))
  fi
 
  zookeeperBrokerRequired=$(oc get statefulset "${resource_cluster_name}"-zookeeper -n "${resource_namespace}" -ojson | jq '.spec.replicas')
  zookeeperBrokerCount=$(oc get statefulset "${resource_cluster_name}"-zookeeper -n "${resource_namespace}" -ojson | jq '.status.readyReplicas')  
  echo "Zookeeper-Brokers $zookeeperBrokerCount/$zookeeperBrokerRequired ok" >> kafka-pods.txt
  if [ $zookeeperBrokerRequired -ne $zookeeperBrokerCount ]; then
    (($podFailCount=$podFailCount+1))
  fi

  adminServerRequired=$(oc get deployment "${resource_cluster_name}"-admin-server -n "${resource_namespace}" -ojson | jq '.spec.replicas')
  adminServerCount=$(oc get deployment "${resource_cluster_name}"-admin-server -n "${resource_namespace}" -ojson | jq '.status.readyReplicas')
  echo "Admin-Server(s) $adminServerCount/$adminServerRequired ok" >> kafka-pods.txt
  if [ $adminServerRequired -ne $adminServerCount ]; then
    (($podFailCount=$podFailCount+1))
  fi

  canaryRequired=$(oc get deployment "${resource_cluster_name}"-canary -n "${resource_namespace}" -ojson | jq '.spec.replicas')
  canaryCount=$(oc get deployment "${resource_cluster_name}"-canary -n "${resource_namespace}" -ojson | jq '.status.readyReplicas')
  echo "Canary(s) $canaryCount/$canaryRequired ok" >> kafka-pods.txt
  if [ $canaryRequired -ne $canaryCount ]; then
    (($podFailCount=$podFailCount+1))
  fi

  kafkaExporterRequired=$(oc get deployment "${resource_cluster_name}"-kafka-exporter -n "${resource_namespace}" -ojson | jq '.spec.replicas')
  kafkaExporterCount=$(oc get deployment "${resource_cluster_name}"-kafka-exporter -n "${resource_namespace}" -ojson | jq '.status.readyReplicas')
  echo "Kafka-Exporter(s) $kafkaExporterCount/$kafkaExporterRequired ok" >> kafka-pods.txt
  if [ $kafkaExporterRequired -ne $kafkaExporterCount ]; then
    (($podFailCount=$podFailCount+1))
  fi

  podCount=$(oc get pods -n "${resource_namespace}" | grep 1/1 | wc -l | sed 's/^ *//g')
  podRequired=$((kafkaBrokerRequired + zookeeperBrokerRequired + adminServerRequired + canaryRequired + kafkaExporterRequired))
  echo "---" >> kafka-pods.txt
  echo "Pod(s)-Running $podCount/$podRequired ok" >> kafka-pods.txt
  if [ $podCount -ne $podRequired ]; then
    podFailCount=$((podFailCount+1))
  fi

  cat kafka-pods.txt | column -t

  printf "_______________________________________________________________  \n"
  printf " Gathering Logs for Unfiltered Kafka Broker Data\n" 
  printf "_______________________________________________________________  \n"

  if [ $kafkaBrokerCount -ne 0 ]; then
    for (( i=0; i<=$kafkaBrokerCount-1; i++))
    do
        oc logs "${resource_cluster_name}"-kafka-"$i" -n "${resource_namespace}" --tail 1000 | egrep -v '.*INFO.*$|.*TRACE.*$' > kafka-"$i".txt
        printf "kafka-"$i".txt created\n"
    done
  fi

  printf "_______________________________________________________________  \n"
  printf " Cluster Events\n" 
  printf "_______________________________________________________________  \n"

  oc get events -n "${resource_namespace}" | egrep -v '.*Normal.*$' > kafka-events.txt
  printf "kafka-events.txt created\n"

  printf "_______________________________________________________________  \n"
  printf " Networking Status\n" 
  printf "_______________________________________________________________  \n"
 
  serviceCount=$(oc get services -n "${resource_namespace}" | tail -n +2 | wc -l | sed 's/^ *//g')
  echo "Service(s) $serviceCount" > kafka-services.txt

  routeCount=$(oc get routes -n "${resource_namespace}" | tail -n +2 | wc -l | sed 's/^ *//g')
  echo "Route(s) $routeCount" >> kafka-services.txt

  cat kafka-services.txt | column -t

  printf "_______________________________________________________________  \n"
  printf " Checking Network Status for Availability\n" 
  printf "_______________________________________________________________  \n"
 
  oc run -q --env brokerCount=$kafkaBrokerCount $resource_cluster_name --image=registry.redhat.io/rhel7/rhel-tools -i --restart=Never --rm -- <test-endpoint.sh 2>/dev/null | column -t

  printf "_______________________________________________________________  \n"
  printf " Storage Status\n" 
  printf "_______________________________________________________________  \n"
 
  pvCount=$(oc get pv | grep "${resource_namespace}" | grep Bound | wc -l | sed 's/^ *//g')
  echo "Persistent-Volume(s) $pvCount bound" > kafka-volumes.txt

  pvcCount=$(oc get pvc -n "${resource_namespace}" | grep Bound | wc -l | sed 's/^ *//g')
  echo "Persistent-Volume-Count $pvcCount bound" >> kafka-volumes.txt

  cat kafka-volumes.txt | column -t

  printf "_______________________________________________________________  \n"
  printf " Secrets\n" 
  printf "_______________________________________________________________  \n"
 
  secretCount=$(oc get secrets -n "${resource_namespace}" | tail -n +2 | wc -l | sed 's/^ *//g')
  printf "Secret(s) $secretCount\n"

  printf "_______________________________________________________________  \n"
  printf " ConfigMaps\n" 
  printf "_______________________________________________________________  \n"
 
  configmapCount=$(oc get configmaps -n "${resource_namespace}" | tail -n +2 | wc -l | sed 's/^ *//g')
  printf "Configmap(s) $configmapCount\n"

  printf "_______________________________________________________________  \n"
  printf " Kafka Cluster Items in order by AGE\n" 
  printf "_______________________________________________________________  \n"

  echo "-------------------------DEPLOYMENTS-----------------------------" > kafka-age.txt
  oc get deployments -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp >> kafka-age.txt
  echo "" >> kafka-age.txt
  echo "-------------------------STATEFULSETS-----------------------------" >> kafka-age.txt
  oc get statefulsets -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp >> kafka-age.txt
  echo "" >> kafka-age.txt
  echo "-------------------------PODS-----------------------------" >> kafka-age.txt
  oc get pods -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp >> kafka-age.txt
  echo "" >> kafka-age.txt
  echo "-------------------------SERVICES-----------------------------" >> kafka-age.txt
  oc get services -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp >> kafka-age.txt
  echo "" >> kafka-age.txt
  echo "-------------------------ROUTES-----------------------------" >> kafka-age.txt
  oc get routes -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp >> kafka-age.txt
  echo "" >> kafka-age.txt
  echo "-------------------------PERSISTENT VOLUMES-----------------------------" >> kafka-age.txt
  oc get pv --sort-by=.metadata.creationTimestamp | grep "${resource_namespace}" >> kafka-age.txt
  echo "" >> kafka-age.txt
  echo "-------------------------PERSISTENT VOLUME CLAIMS-----------------------------" >> kafka-age.txt
  oc get pvc -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp >> kafka-age.txt
  echo "" >> kafka-age.txt
  echo "-------------------------SECRETS-----------------------------" >> kafka-age.txt
  oc get secrets -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp >> kafka-age.txt
  echo "" >> kafka-age.txt
  echo "-------------------------CONFIGMAPS-----------------------------" >> kafka-age.txt
  oc get configmaps -n "${resource_namespace}" --sort-by=.metadata.creationTimestamp >> kafka-age.txt

  printf "kafka-status-age.txt created\n"

  totalCount=$((podCount + serviceCount + pvCount + pvcCount + deploymentCount + kafkaBrokerCount + zookeeperBrokerCount))
 
  printf "_______________________________________________________________  \n"
  printf " Total Resources check $totalCount\n"
  echo "Pod(s) $podCount/$podRequired" > kafka-total-resources.txt
  echo "Service(s) $serviceCount" >> kafka-total-resources.txt
  echo "Route(s) $routeCount" >> kafka-total-resources.txt
  echo "PV(s) $pvCount" >> kafka-total-resources.txt
  echo "PVC $pvcCount" >> kafka-total-resources.txt
  echo "Secret(s) $secretCount" >> kafka-total-resources.txt
  echo "Configmap(s) $configmapCount" >> kafka-total-resources.txt
  cat kafka-total-resources.txt | column -t
  printf "_______________________________________________________________  \n"

  if [[ $podFailCount -ne 0 ]]; then
    printf "_______________________________________________________________  \n"
    printf " FAILURES\n"
    printf "Pod-Failure(s) $podFailCount Total-Pod(s) $podCount/$podRequired\n" | column -t
  fi

}

main
