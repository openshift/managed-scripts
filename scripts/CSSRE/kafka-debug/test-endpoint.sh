#!/bin/bash
resource_cluster_name=$(cat /etc/hostname)
bCount=$((brokerCount-1))
test_endpoint() 
{
  nc -z -w 2 "$1" "$2"
  if [ $? -eq 0 ]; then
    echo -e "$1 $2 ok"
  else
    echo "$1" "$2" FAILED
  fi
}

test_endpoint "${resource_cluster_name}"-admin-server 8443
test_endpoint "${resource_cluster_name}"-canary 8080

for i in $(seq 0 $bCount)
do
  test_endpoint "${resource_cluster_name}"-kafka-"$i" 9094
done

test_endpoint "${resource_cluster_name}"-kafka-bootstrap 9096
test_endpoint "${resource_cluster_name}"-kafka-brokers 9096
test_endpoint "${resource_cluster_name}"-kafka-external-bootstrap 9094
