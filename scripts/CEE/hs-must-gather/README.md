# HyperShift mustgather
This script runs hypershift dump command to fetch logs from management cluster HCP namespace and hosted cluster. 


## Usage

Parameters:
- CLUSTER_ID: Hosted cluster internal ID.

Steps:
- Login to https://access.redhat.com/sftp-token/
- Generate a one-time upload token, mark the username and token.
- For internal accounts, set internal=true in the later commands.

```bash
## In management cluster
oc create secret generic hs-mg-creds --from-literal=username=<username> --from-literal=internal=false --from-literal=password=<token>  --from-literal=caseid=<case-number> -n openshift-backplane-managed-scripts
ocm backplane managedjob create CEE/hs-must-gather -p CLUSTER_ID=<internal-id>
```
