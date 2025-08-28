# HyperShift mustgather - Manifests/CRs only
This script executes the adm must-gather command to collect Manifests/CRs from
both the management cluster's HCP namespace and the hosted cluster. 

Importantly, after gathering the data, the script also scans and removes files containing potentially
sensitive information to ensure safer sharing and archiving.

The script will upload the compressed dump to the [SFTP](https://access.redhat.com/articles/5594481#TOC32).

## Usage

Parameters:
- CLUSTER_ID: hosted cluster id.

In the management cluster:
```bash
ocm backplane managedjob create troubleshooting/hs-manifest-gather -p CLUSTER_ID=my-hs-cluster-id
```

Note:
The debug handler is disabled in the production environment. Logs can not be collected, Please use `osdctl cluster dt gather-logs` or `osdctl hcp must-gather` to collect logs in the production environment.
