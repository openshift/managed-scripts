# get-kafka-topics

This scripts runs the `rolling-restart-brokers.sh` script to manually roll the Kafka brokers.

## Usage

### Running locally

```bash
Usage: ./rolling-restart-brokers.sh -n KAFKA_NAMESPACE [-s STATEFUL_SET | -p POD]

# Examples
./rolling-restart-brokers.sh -n kafka-ID
./rolling-restart-brokers.sh -n kafka-ID -s zookeeper
./rolling-restart-brokers.sh -n kafka-ID -p broker-kafka-0
```

### Running as a managed script

For use as a managed script, parameters are passed as environment variables.

```bash
ocm backplane managedjob create CSSRE/rolling-restart-brokers -p kafka_namespace=<KAFKA_NAMESPACE> [statefulset=STATEFUL_SET | pod=POD]

# Examples
ocm backplane managedjob create CSSRE/rolling-restart-brokers -p kafka_namespace=my-kafka
ocm backplane managedjob create CSSRE/rolling-restart-brokers -p kafka_namespace=my-kafka statefulset=kafka
ocm backplane managedjob create CSSRE/rolling-restart-brokers -p kafka_namespace=my-kafka pod=pod-zookeeper-0 
```



