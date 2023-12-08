# INFRA NODE RESIZE

## Purpose

This script will help automate infra node resize without having the need to elevate access permissions.

## Usage
To use this script you will need to first login to a Hive shard.
This script runs on a production Hive shard and helps resize the infra nodes of the cluster to the desired size. Meaning, SREs do not have to elevate permissions to perform this operation.

## Create the ManagedJob to resize infra-nodes
```
ocm backplane login <hive_shard>

ocm backplane managedjob create SREP/infra-node-resize -p CLUSTER_ID=<Internal CLUSTER_ID> -p INSTANCE_SIZE=<desired instance size>
```