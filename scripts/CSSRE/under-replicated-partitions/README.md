# Under Replicated Partitions

This script is intended to be used when the `UnderReplicatedPartitions` alert fires. The script uses the `kafka-topics.sh` script built into the Kafka brokers to determine which brokers are not in-sync and if they can be safely restarted and prints out this information.

## Running as a managed-script

For use as a managed script, parameters are provided as environmental variables.

```
ocm backplane managedjob create CSSRE/under-replicated-partitions -p KAFKA_NAMESPACE=<KAFKA_NAMESPACE>
ocm backplane managedjob create CSSRE/under-replicated-partitions -p KAFKA_NAMESPACE=<KAFKA_NAMESPACE> -p LOG_LEVEL=debug
```
