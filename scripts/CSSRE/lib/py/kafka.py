import openshift as oc
import copy

def get_kafka_cluster(namespace):
  with oc.project(namespace), oc.timeout(5*60):
    return next(iter(oc.selector('kafkas').objects() or []), None)

def check_all_brokers_active(namespace, logger):
  with oc.project(namespace), oc.timeout(5*60):
    logger.debug("Checking if Kafka pods are active")
    pods = oc.selector('pods', labels={"app.kubernetes.io/name": "kafka"}).objects()
    num_pods_ready = 0
    for pod in pods:
      ready = oc.selector('pod/'+pod.name()).object().model.status.conditions.can_match(
        {
            'type': 'Ready',
            'status': "True",
        }
      )
      if ready:
        num_pods_ready +=1
      logger.debug("Kafka Pod %s ready: %s." % (pod.name(), ready))
  return (num_pods_ready, len(pods))

def run_kafka_topics_script(namespace, kafka, filter) :
  with oc.project(namespace), oc.timeout(10*60):

    cmd = "-i statefulset/"+kafka+"-kafka -c kafka -- env - bin/kafka-topics.sh --bootstrap-server localhost:9096 --describe " + filter
    return oc.invoke('exec', cmd.split())

def get_out_of_sync_brokers(logger, topics):
  out_of_sync_brokers = set()
  for partition in iter(topics.splitlines()):

    replicas = create_broker_list(partition.split('\t')[-2])
    isr = create_broker_list(partition.split('\t')[-1])
    
    topic = partition.split('\t')[1].split(' ')[-1]
    p = partition.split('\t')[2].split(' ')[-1]

    out_of_sync_brokers.update(check_replicas_in_sync(logger, topic, p, replicas, isr))
  return out_of_sync_brokers

def create_broker_list(brokers):
  return brokers.split(" ")[-1].split(',')

def check_replicas_in_sync(logger, topic, partition, replicas, isr):
  brokers = set()
  for r in replicas:
    if r not in isr:
      logger.debug("Topic %s, partitions %s does not have an in sync replica on kafka-%s" % (topic, partition, r))
      brokers.update(r)
  return brokers

def check_broker_safe_restart(logger, namespace, kafka, topics, brokers_to_restart):
  brokers = copy.deepcopy(brokers_to_restart)

  with oc.project(namespace), oc.timeout(5*60):

    if check_partitions_with_no_leader(logger, namespace, kafka):
      return set()
    under_min_isr_partitions = run_kafka_topics_script(namespace, kafka.name(), "--under-min-isr-partitions")
    if under_min_isr_partitions.out().count('Partition') == 0:
      return brokers

  for partition in iter(topics.out().splitlines()):
    leader = partition.split('\t')[-3].split(' ')[-1]
    if leader in brokers:
      if len(create_broker_list(partition.split('\t')[-1])) < get_min_isr(namespace,kafka):
        logger.info("Broker %s cannot be safely restarted because it is partition leader for under min ISR partition(s)." % leader)
        brokers.remove(leader)

  return brokers

def check_partitions_with_no_leader(logger, namespace, kafka):
  offline_partitions = run_kafka_topics_script(namespace, kafka.name(), "--unavailable-partitions")
  for partition in iter(offline_partitions.out().splitlines()):
    leader = partition.split('\t')[-3].split(' ')[-1]
    if leader == "none"  or leader == -1:
      logger.debug("There are offline partitions. The controller is not able to elect one of the in-sync replicas as the new leader. Force leader relection")
      return True
  return False

def get_min_isr(namespace,kafka):
  with oc.project(namespace), oc.timeout(5*60):
    return oc.selector(['kafka/'+kafka.name()]).object().model.spec.kafka.config['min.insync.replicas']