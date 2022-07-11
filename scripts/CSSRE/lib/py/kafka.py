from py.logger import Logger
from py.exceptions import StatefulsetExecConnectionError, NotManagedKafkaNamespace
import copy

class Kafka:
  """
  A Kafka utility class for getting information about Kafka clusters
  """
  def __init__(self, oc, settings, logger_name=__name__):
    self._oc = oc
    self.settings = settings
    self.logger = Logger.get_logger(logger_name)

  @property
  def oc(self): 
      return self._oc


  def check_namespace_managed_kafka(self, namespace):
    """
    Checks if a given namespace is a managed Kafka namespace, throws an error if it's not.

    Parameters:
      namespace (str): Namespace to check.
    """
    label_value = self._oc.selector('namespace/'+namespace).objects()[0].get_label(self.settings.MANAGED_KAFKA_LABEL_KEY)
    self.logger.debug("Looking for label %s:%s on namespace %s" % (self.settings.MANAGED_KAFKA_LABEL_KEY,self.settings.MANAGED_KAFKA_LABEL_VALUE, namespace))
    if label_value != self.settings.MANAGED_KAFKA_LABEL_VALUE:
      raise NotManagedKafkaNamespace(
        f"Namespace not labeled {self.settings.MANAGED_KAFKA_LABEL_KEY}:{self.settings.MANAGED_KAFKA_LABEL_VALUE}"
      )

  def get_kafka_cluster(self, namespace):
    """
    Gets Kafka cluster in a given namespace.

    Parameters:
      namespace (str): Namespace the get Kafka cluster.

    Returns:
      (apiobject): OpenShift API object for the Kafka cluster.

    """
    with self._oc.project(namespace), self._oc.timeout(self.settings.OC_TIMEOUT_5_MINUTES):
      return next(iter(self._oc.selector('kafkas').objects() or []), None)


  def check_all_brokers_active(self, namespace):
    """
    Check if all brokers for a Kafka are ready.

    Parameters:
      namespace (str): Namespace the get Kafka cluster.

    Returns:
      (int))num_pods_ready: Number of ready brokers. 
      (int)pods: Total nuymber of brokers.

    """
    with self._oc.project(namespace), self._oc.timeout(self.settings.OC_TIMEOUT_5_MINUTES):
      self.logger.debug("Checking if Kafka pods are active")
      pods = self._oc.selector('pods', labels={"app.kubernetes.io/name": "kafka"}).objects()
      num_pods_ready = 0
      for pod in pods:
        ready = self._oc.selector('pod/'+pod.name()).object().model.status.conditions.can_match(
          {
              'type': 'Ready',
              'status': "True",
          }
        )
        if ready:
          num_pods_ready +=1
        self.logger.debug("Kafka Pod %s ready: %s." % (pod.name(), ready))
    return (num_pods_ready, len(pods))


  def run_kafka_topics_script(self, namespace, kafka, topic="", filter="") :
    """
    Runs the kafka-topics.sh script on a kafka pod in a given namespace.

    Parameters:
      namespace (str): Namespace of the kafka.
      kafka (str): Name of the kafka cluster.
      filter (str): a filter for partitions (--under-replicated-partitions, --under-min-isr-partitions, --unavailable-partitions).

    Returns
      (apiobject): OpenShift API object with description of topics and partitions.
    """
    with self._oc.project(namespace), self._oc.timeout(self.settings.OC_TIMEOUT_5_MINUTES):

      cmd = "-i statefulset/"+kafka+"-kafka -c kafka -- env - bin/kafka-topics.sh --bootstrap-server localhost:9096 --describe "
      if topic:
        cmd = cmd + " --topic " + topic
      if filter:
        cmd = cmd + " --" + filter
      try:
        return self._oc.invoke('exec', cmd.split())
      except self._oc.OpenShiftPythonException:
        raise StatefulsetExecConnectionError(
          f"Connection to Statefulset failed: statefulset/{kafka}-kafka"
        ) from None


  def get_out_of_sync_brokers(self, topics):
    """
    Checks for any out-of-sync brokers given topic description from kafka-topics.sh.

    Parameters:
      topics (str): Topics descriptions as outputed by kafka-topic.sh script.

    Returns
      list: List of brokers that are not in-sync.
    """
    out_of_sync_brokers = set()
    for partition in iter(topics.splitlines()):

      replicas = self.create_broker_list(partition.split('\t')[-2])
      isr = self.create_broker_list(partition.split('\t')[-1])
      
      topic = partition.split('\t')[1].split(' ')[-1]
      p = partition.split('\t')[2].split(' ')[-1]

      out_of_sync_brokers.update(self.check_replicas_in_sync(topic, p, replicas, isr))
    return out_of_sync_brokers


  def create_broker_list(self, brokers):
    """
    Converts comma separate list of brokers to list

    Parameters:
      brokers: (str) comma separated list of brokers outputted by kafka-topics.sh

    Returns
      list: list of brokers
    """
    return brokers.split(" ")[-1].split(',')


  def check_replicas_in_sync(self, topic, partition, replicas, isr):
    """
    Compares list of replica brokers with list of in-sync brokers to find any out-of-sync brokers for a given partition.
    
    Parameters:
      topic (str): The topic the partition belongs to
      partition (str): The partition to check for out-of-sync brokers.
      replicas (list): The list of brokers which should have replicas for the given partition.
      isr (list): The in sync replicas for the given partition.

    Returns:
      list: List of brokers which which are not in-sync for the given partition.
    """
    brokers = set()
    for r in replicas:
      if r not in isr:
        self.logger.debug("Topic %s, partitions %s does not have an in sync replica on kafka-%s" % (topic, partition, r))
        brokers.update(r)
    return brokers


  def check_broker_safe_restart(self, namespace, kafka, topics, brokers_to_restart):
    """
    Checks if brokers are safe to restart. A brokers is considered safe to restart if any of the following are true:
    There are no under min ISR partitions.
    The broker is not a partition leader for any partitions
    Any partition for which the broker is leader has at least one other in-sync replica.

    Parameters:
      namespace (str): Namespace of the kafka.
      kafka (str): Name of the kafka cluster.
      topics (str): topics description as outputed by kafka-topic.sh script
      brokers_to_restart (list): List of brokers to check for safe restart.

    Returns
      list: List of brokers which can be safely restarted.
    """
    brokers = copy.deepcopy(brokers_to_restart)

    with self._oc.project(namespace), self._oc.timeout(self.settings.OC_TIMEOUT_5_MINUTES):

      if self.check_partitions_with_no_leader(namespace, kafka):
        return set()
      under_min_isr_partitions = self.run_kafka_topics_script(namespace, kafka.name(), filter="under-min-isr-partitions")
      if under_min_isr_partitions.out().count('Partition') == 0:
        return brokers

    for partition in iter(topics.out().splitlines()):
      leader = partition.split('\t')[-3].split(' ')[-1]
      if leader in brokers:
        if len(self.create_broker_list(partition.split('\t')[-1])) < self.get_min_isr(namespace,kafka):
          self.logger.info("Broker %s cannot be safely restarted because it is partition leader for under min ISR partition(s)." % leader)
          brokers.remove(leader)

    return brokers


  def check_partitions_with_no_leader(self, namespace, kafka):
    """
    Checks if there are any partitions with no leader in a given kafka, i.e offline partitions. 

    Parameters:
      namespace (str): Namespace of the kafka.
      kafka (str): Name of the kafka cluster.

    Returns
      bool: True if there are offline partitions. 
    """
    offline_partitions = self.run_kafka_topics_script(namespace, kafka.name(), filter="unavailable-partitions")
    for partition in iter(offline_partitions.out().splitlines()):
      leader = partition.split('\t')[-3].split(' ')[-1]
      if leader == "none"  or leader == -1:
        self.logger.debug("There are offline partitions. The controller is not able to elect one of the in-sync replicas as the new leader. Force leader relection")
        return True
    return False


  def get_min_isr(self, namespace,kafka):
    """
    Get's the configred min ISR for for a given Kafka.

    Parameters:
      namespace (str): Namespace of the kafka.
      kafka (str): Name of the kafka cluster.

    Returns
      int: The default min ISR for the Kafka.
    """
    with self._oc.project(namespace), self._oc.timeout(self.settings.OC_TIMEOUT_5_MINUTES):
      return self._oc.selector(['kafka/'+kafka.name()]).object().model.spec.kafka.config['min.insync.replicas']