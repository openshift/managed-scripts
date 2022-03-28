# Cluster Operator Status

## Description

This script provides a general summary of information concerning the status of a managed kafka cluster:

- Basic summary (Available State / Current Exisitng Resources / Bound Volumes)
- Prints to terminal each identified resource and current state
- Broker logs (Recent 1000 lines with INFO/TRACE removed)

## Usage

The script can target a specific managed kafka cluster through the use of the `resource_namespace` and `resource_cluster_name` environment variable / backplane parameter.

If the environment variables are empty or not set, the script will failout.

```bash
ocm backplane managedjob create CSSRE/kafka-debug -p resource_namespace=<Managed Kafka Namespace> resource_cluster_name=<Managed Kafka Name> 
```

The script will list out the following in order:
- Deployment/StatefulSet(s)
- Pod Status
- Log creation in relation to Kafka Brokers
    - kafka-<broker #>.txt
- Cluster Events
    - kafka-events.txt
- Service/Route (Amount/Status)
- PV/PVC (Currently Bound)
- Secrets (Amount)
- ConfigMaps (Amount)

The script will generate filtered logs for the kafka brokers and cluster events to assist in narrowing down potential issues (Removes INFO & TRACE Logs from last 1000 lines)
