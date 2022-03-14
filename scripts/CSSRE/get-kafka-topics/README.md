# get-kafka-topics

This scripts runs the `kafka-topics.sh` script built into Kafka brokers to provide details of the Kafka's topics and partitions.

## Usage

### Running locally

```bash
Usage: ./get-kafka-topics.sh -n KAFKA_NAMESPACE [-t TOPIC] [-f <under-replicated-partitions|under-min-isr-partitions|unavailable-partitions>]

# Examples
./get-kafka-topics.sh -n my-kafka
./get-kafka-topics.sh -n my-kafka -t canary
./get-kafka-topics.sh -n my-kafka -t canary -f under-replicated-partitions
```

### Running as managed script

For use as a managed script, parameters are passed as environment variables.

```bash
ocm backplane managedjob create CSSRE/get-kafka-topics -p kafka_namespace=<KAFKA_NAMESPACE> [topic=TOPIC] [filter=<under-replicated-partitions|under-min-isr-partitions|unavailable-partitions>]

# Examples
ocm backplane managedjob create CSSRE/get-kafka-topics -p kafka_namespace=my-kafka
ocm backplane managedjob create CSSRE/get-kafka-topics -p kafka_namespace=my-kafka topic=canary
ocm backplane managedjob create CSSRE/get-kafka-topics -p kafka_namespace=my-kafka topic=canary filter=unavailable-partitions
```



