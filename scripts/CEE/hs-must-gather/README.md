# HyperShift mustgather
This script executes the hypershift dump command to collect logs and relevant information from
both the management cluster's HCP namespace and the hosted cluster. 

Importantly, after gathering the data, the script also scans and removes files containing potentially
sensitive information to ensure safer sharing and archiving.

## Usage

Parameters:
- CLUSTER_NAME: hosted cluster name.

```bash
ocm backplane managedjob create CEE/hs-must-gather -p CLUSTER_NAME=my-hs-cluster-name 
```
