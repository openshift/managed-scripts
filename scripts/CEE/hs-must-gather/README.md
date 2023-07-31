# Hypershift mustgather

This script run must gather commands in both the hosted and management clusters. 


## Usage

Parameters:
- CLUSTER_NAME: hosted cluster name.
- DUMP_DIR: Must gather dump directory path.

```bash
ocm backplane managedjob create CEE/hs-must-gather -p CLUSTER_NAME=my-hs-cluster-name -p DUMP_DIR=/path/for-dump/

```



