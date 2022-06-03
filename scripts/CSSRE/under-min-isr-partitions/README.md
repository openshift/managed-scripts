# Under Min ISR Partitions

This script is intended to be used when the `UnderMinIsrPartitionCount` alert fires. The script uses the `kafka-topics.sh` script built into the Kafka brokers to determine which brokers are not in-sync and if they can be safely restarted and prints out this information.

## Usage
Parameters should be provided as environmental variables.

## Running locally
```bash
KAFKA_NAMESPACE=<KAFKA_NAMESPACE> python under-min-isr-partitions.py

# Examples
KAFKA_NAMESPACE=my-kafka python under-min-isr-partitions.py
KAFKA_NAMESPACE=my-kafka python under-min-isr-partitions.py --log-level=debug

```

## Running as a managed-script


```bash
ocm backplane managedjob create CSSRE/under-min-isr-partitions -p kafka_namespace=<KAFKA_NAMESPACE> [LOG_LEVEL=<LOG_LEVEL>]

# Examples
ocm backplane managedjob create CSSRE/under-min-isr-partitions -p KAFKA_NAMESPACE=<KAFKA_NAMESPACE>
ocm backplane managedjob create CSSRE/under-min-isr-partitions -p KAFKA_NAMESPACE=<KAFKA_NAMESPACE> -p LOG_LEVEL=debug
```
