# get-kafka-topics

This script runs the `kafka-topics.sh` script built into Kafka brokers to provide details of the Kafka's topics and partitions.

## Usage
Parameters should be provided as environmental variables.

### Running locally

```bash

KAFKA_NAMESPACE=<KAFKA_NAMESPACE> [TOPIC=<TOPIC>] [FILTER=<under-replicated-partitions|under-min-isr-partitions|unavailable-partitions>] python get-kafka-topics.py

# Examples
KAFKA_NAMESPACE=my-kafka python get-kafka-topics.py
KAFKA_NAMESPACE=my-kafka python get-kafka-topics.py --log-level-debug
KAFKA_NAMESPACE=my-kafka TOPIC=canary python get-kafka-topics.py
KAFKA_NAMESPACE=my-kafka FILTER=under-replicated-partitions python get-kafka-topics.py
```

### Running as managed script

```bash
ocm backplane managedjob create LPSRE/get-kafka-topics -p KAFKA_NAMESPACE=<KAFKA_NAMESPACE> [TOPIC=<TOPIC>] [FILTER=<under-replicated-partitions|under-min-isr-partitions|unavailable-partitions>] [LOG_LEVEL=<LOG_LEVEL>]

# Examples
ocm backplane managedjob create LPSRE/get-kafka-topics -p KAFKA_NAMESPACE=my-kafka
ocm backplane managedjob create LPSRE/get-kafka-topics -p KAFKA_NAMESPACE=my-kafka -p TOPIC=canary
ocm backplane managedjob create LPSRE/get-kafka-topics -p KAFKA_NAMESPACE=my-kafka -p TOPIC=canary -p FILTER=unavailable-partitions
```

