# Hypershift mustgather
This script runs hypershift dump command to fetch logs from management cluster HCP namespace and hosted cluster. 


## Usage

Parameters:
- CLUSTER_NAME: hosted cluster name.

```bash
ocm backplane managedjob create CEE/hs-must-gather -p CLUSTER_NAME=my-hs-cluster-name 
```



