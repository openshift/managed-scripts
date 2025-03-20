# Update Upgrade Policy State

## Description

The `update_upgrade_policy` managed script allows you to cancel the upgrade policy of the current OpenShift cluster. The script automates the following processes:

1. Fetches the authentication token for accessing the OpenShift API.
2. Obtains the UUID of the current OpenShift cluster.
3. Uses the cluster's UUID to fetch its unique ID.
4. Retrieves the UUID of the upgrade policy for the current cluster.
5. Sets the upgrade policy state of the cluster to "cancelled".

## Usage

To cancel the upgrade policy of the current cluster, you can run the following commands for prod and staging clusters:

For production clusters (prod is the default parameter , hence it needs no explicit specification) : 

```bash
ocm backplane managedjob create SREP/update-upgrade-policy-state
```

For staging clusters (need to specify env=stage as parameter): 

```bash
ocm backplane managedjob create SREP/update-upgrade-policy-state -p env=stage
```