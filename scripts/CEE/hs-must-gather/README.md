# HyperShift mustgather
This script executes the hypershift dump command to collect logs and relevant information from
both the management cluster's HCP namespace and the hosted cluster. 

Importantly, after gathering the data, the script also scans and removes files containing potentially
sensitive information to ensure safer sharing and archiving.

The script will upload the compressed dump to the [SFTP](https://access.redhat.com/articles/5594481#TOC32).

## Usage

Parameters:
- CLUSTER_ID: hosted cluster id.

In the management cluster:
```bash
ocm backplane managedjob create CEE/hs-must-gather -p CLUSTER_ID=my-hs-cluster-id
```
