# get-kafka-topics

This scripts runs the `rolling-restart-brokers.sh` script to manually roll the Kafka brokers. Up to Strimzi v0.32.x both Statefulsets and Strimzipodsets may be enabled. Beyond v0.32.x only Strimzipodsets will work. 

## Usage

### Running locally

```bash
Usage: ./rolling-restart-brokers.sh -n KAFKA_NAMESPACE [-s STATEFULSET|STRIMZIPODSET | -p POD]

# Examples
./rolling-restart-brokers.sh -n kafka-namespace
./rolling-restart-brokers.sh -n kafka-namespace -s zookeeper
./rolling-restart-brokers.sh -n kafka-namespace -p broker-kafka-0
```

### Running as a managed script

For use as a managed script, parameters are passed as environment variables.

```bash
ocm backplane managedjob create CSSRE/rolling-restart-brokers -p kafka_namespace=<KAFKA_NAMESPACE> [s_set=STATEFULSET|STRIMZIPODSET | pod=POD]

# Examples
ocm backplane managedjob create CSSRE/rolling-restart-brokers -p kafka_namespace=my-kafka
ocm backplane managedjob create CSSRE/rolling-restart-brokers -p kafka_namespace=my-kafka s_set=kafka
ocm backplane managedjob create CSSRE/rolling-restart-brokers -p kafka_namespace=my-kafka pod=pod-zookeeper-0 
```



