# Update Upgrade Policy State

## Description

The managed script `update_upgrade_policy` provides the ability to update the state of a specific OpenShift cluster's upgrade policy. It fetches the current state and compares it to the desired state provided, updating it if necessary.

## Usage

The script expects two command-line arguments, the cluster name (-c) and the desired state (-s).
If you want to target a specific cluster and state:

```bash
ocm backplane managedjob create SREP/update-upgrade-policy-state -p CLUSTER_NAME=my-cluster -p DESIRED_STATE=scheduled
```

or

```bash
ocm backplane managedjob create SREP/update-upgrade-policy-state
```

## Parameters

- `CLUSTER_NAME`: The name of the cluster whose upgrade policy state you wish to update.
- `DESIRED_STATE`: The state you wish to set for the cluster's upgrade policy. Valid values might include states like "started", "scheduled", "cancelled", etc. Ensure you're using a valid state for your specific OpenShift Cluster Manager instance.