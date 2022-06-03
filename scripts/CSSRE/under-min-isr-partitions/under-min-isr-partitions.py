import argparse
import sys

LIB_PATH = "/managed-scripts/CSSRE/lib"
# Use sys.path.insert because PYTHONPATH's support is unclear
sys.path.insert(0, LIB_PATH)

from py.script import Script
from py.kafka import Kafka

class UnderMinIsrPartitions(Script):
  def __init__(self):
    super().__init__(logger_name="Under Min ISR Partitions", env_vars=["KAFKA_NAMESPACE"], check_env_var=False)

  def create_parser(self):
    self.parser = argparse.ArgumentParser(description="Checks for Kafka under min ISR partitions.")
    self.parser.add_argument("--kafka-namespace", help="The namespace of the kafka")
    self.parser.add_argument("--log-level", help="Set logging level.")

  def run(self):
    self.logger.debug("---Running managed script: Under Min ISR Partitions---")

    kafka = Kafka(self.oc, self.settings, logger_name="Under Min ISR Partitions")
    kafka.check_namepace_managed_kafka(self.KAFKA_NAMESPACE)
    cluster = kafka.get_kafka_cluster(self.KAFKA_NAMESPACE)
    
    if cluster is None:
      self.exit(
        self.logger.error("No kafka found in namespace %s" % self.KAFKA_NAMESPACE)
      )
    self.logger.info("Found Kafka %s in namespace %s" % (cluster.name(), self.KAFKA_NAMESPACE))

    num_pods_ready, num_pods = kafka.check_all_brokers_active(self.KAFKA_NAMESPACE)
    if num_pods_ready < num_pods:
      self.exit(
        self.logger.info(
          '''There are pods in a not ready state.
          This is the most likely cause of under min ISR partitions and this script will not be able to resolve the under replicated partitions while there are pods in a not ready state.
          Kafka pods ready: %d/%d''' % (num_pods_ready, num_pods))
      )

    topics = kafka.run_kafka_topics_script(self.KAFKA_NAMESPACE, cluster.name(), filter="under-min-isr-partitions")
    if topics.out().count('Partition') == 0:
      self.exit(
        self.logger.info("There are no under min ISR partitions")
      )
      
    self.logger.info("There are %d under min ISR partitions:\n%s" % (topics.out().count('Partition'), topics.out()))

    out_of_sync_brokers = kafka.get_out_of_sync_brokers(topics.out())
    self.logger.info("The following brokers should be restarted: %s" % out_of_sync_brokers)

    safe_to_restart_brokers = kafka.check_broker_safe_restart(self.KAFKA_NAMESPACE, cluster, topics, out_of_sync_brokers)
    self.logger.info("The following brokers can be safely restarted %s" % safe_to_restart_brokers)

if __name__ == "__main__":
  UnderMinIsrPartitions()
