# ETCD Health Check script usage

This script creates a job that runs in the namespace `openshift-backplane-managed-scripts`, which inside the logs of the job pod have the result of the health check.
## Create the job to run the health check
ocm backplane managedjob create CEE/etcd-health-check

## Getting the result of the job in a file
ocm backplane managedjob logs <JOBNAME> | gunzip > etcd-health-check.txt
  
```
$ ocm backplane managedjob logs openshift-job-tsgjl

>> etcdctl endpoint status
+-------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|        ENDPOINT         |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+-------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://10.X.X.X:2379 | 4a94c4b27a89a05e |   3.5.6 |  405 MB |      true |      false |        79 |  843479429 |          843479429 |        |
| https://10.X.X.X:2379 | 87d3aff948cdb0aa |   3.5.6 |  407 MB |     false |      false |        79 |  843479430 |          843479430 |        |
|  https://10.X.X.X:2379 | 50230d44f7ca0662 |   3.5.6 |  406 MB |     false |      false |        79 |  843479430 |          843479430 |        |
+-------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+

>> etcdctl endpoint health
+-------------------------+--------+-------------+-------+
|        ENDPOINT         | HEALTH |    TOOK     | ERROR |
+-------------------------+--------+-------------+-------+
| https://10.X.X.X:2379 |   true | 10.844978ms |       |
| https://10.X.X.X:2379 |   true | 11.271803ms |       |
|  https://10.X.X.X:2379 |   true | 14.400458ms |       |
+-------------------------+--------+-------------+-------+

>> etcdctl member list
+------------------+---------+----------------------------+-------------------------+-------------------------+------------+
|        ID        | STATUS  |            NAME            |       PEER ADDRS        |      CLIENT ADDRS       | IS LEARNER |
+------------------+---------+----------------------------+-------------------------+-------------------------+------------+
| 4a94c4b27a89a05e | started | ip-10-X-X-X.ec2.internal | https://10.X.X.X:2380 | https://10.X.X.X:2379 |      false |
| 50230d44f7ca0662 | started |  ip-10-X-X-X.ec2.internal |  https://10.X.X.X:2380 |  https://10.X.X.X:2379 |      false |
| 87d3aff948cdb0aa | started | ip-X-X-X.ec2.internal | https://10.X.X.X:2380 | https://10.X.X.X:2379 |      false |
+------------------+---------+----------------------------+-------------------------+-------------------------+------------+**
```
