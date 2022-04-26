import argparse
import sys

LIB_PATH = "/managed-scripts/CSSRE/lib"
# Use sys.path.insert because PYTHONPATH's support is unclear
sys.path.insert(0, LIB_PATH)

from py.script import Script
import py.kafka as Kafka


class UnderReplicatedPartitions(Script):
  def __init__(self):
    super().__init__(env_vars=["KAFKA_NAMESPACE"], check_env_var=False)

  def create_parser(self):
    self.parser = argparse.ArgumentParser(description="Checks for Kafka under replicated partitions.")
    self.parser.add_argument("--kafka-namespace", help="The namespace of the kafka")
    self.parser.add_argument("--log-level", help="Set logging level.")

  def run(self):
    self.logger.debug("---Running managed script: Under Replicated Partitions---")

    kafka = Kafka.get_kafka_cluster(self.KAFKA_NAMESPACE)
    
    if kafka is None:
      self.logger.error("No kafka found in namespace %s" % self.KAFKA_NAMESPACE)
      sys.exit()
    self.logger.info("Found Kafka %s in namespace %s" % (kafka.name(), self.KAFKA_NAMESPACE))

    num_pods_ready, num_pods = Kafka.check_all_brokers_active(self.KAFKA_NAMESPACE, self.logger)
    if num_pods_ready < num_pods:
      self.logger.info(
        '''There are pods in a not ready state.
        This is the most likely cause of under replicated partitions and this script will not be able to resolve the under replicated partitions while there are pods in a not ready state.
        Kafka pods ready: %d/%d''' % (num_pods_ready, num_pods))
      sys.exit()

    topics = Kafka.run_kafka_topics_script(self.KAFKA_NAMESPACE, kafka.name(), "--under-replicated-partitions")
    if topics.out().count('Partition') == 0:
      self.logger.info("There are no under replicated partitions")
      sys.exit()
    self.logger.info("There are %d under replicated partitions:\n%s" % (topics.out().count('Partition'), topics.out()))


    out_of_sync_brokers = Kafka.get_out_of_sync_brokers(self.logger, topics.out())
    self.logger.info("The following brokers should be restarted: %s" % out_of_sync_brokers)

    safe_to_restart_brokers = Kafka.check_broker_safe_restart(self.logger, self.KAFKA_NAMESPACE, kafka, topics, out_of_sync_brokers)
    self.logger.info("The following brokers can be safely restarted %s" % safe_to_restart_brokers)

if __name__ == "__main__":
  UnderReplicatedPartitions()
