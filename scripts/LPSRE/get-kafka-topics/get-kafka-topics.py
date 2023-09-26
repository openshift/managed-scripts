import argparse
import sys

LIB_PATH = "/managed-scripts/LPSRE/lib"
# Use sys.path.insert because PYTHONPATH's support is unclear
sys.path.insert(0, LIB_PATH)

from py.script import Script
from py.kafka import Kafka

class KafkaTopics(Script):
  def __init__(self):
    super().__init__(logger_name="Kafka Topics", env_vars=["KAFKA_NAMESPACE", "TOPIC", "FILTER"], check_env_var=False)

  def create_parser(self):
    self.parser = argparse.ArgumentParser(description="Checks for Kafka under replicated partitions.")
    self.parser.add_argument("--kafka-namespace", help="The namespace of the kafka")
    self.parser.add_argument("--log-level", help="Set logging level.")
    
  def run(self):
    self.logger.debug("---Running managed script: Kafka Topics---")

    kafka = Kafka(self._oc, self.settings, logger_name="Under Replicated Partitions")
    cluster = kafka.get_kafka_cluster(self.KAFKA_NAMESPACE)
    
    if cluster is None:
      self.logger.error("No kafka found in namespace %s" % self.KAFKA_NAMESPACE)
      sys.exit()
    self.logger.info("Found Kafka %s in namespace %s" % (cluster.name(), self.KAFKA_NAMESPACE))

    topics = kafka.run_kafka_topics_script(self.KAFKA_NAMESPACE, cluster.name(), topic=self.TOPIC, filter=self.FILTER)

    if topics.out():
      self.logger.info("\n%s" % topics.out())
    else:
      self.logger.info("There are no %s partitions" % self.FILTER)
  
if __name__ == "__main__":
  KafkaTopics()