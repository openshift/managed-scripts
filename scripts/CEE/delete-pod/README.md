# Delete Openshift Pod Script

## Purpose

This script is designed to delete a pod from OpenShift cluster core namespace.

## Usage

Parameters:
- POD_NAME: Name of pod to delete.
- NAMESPACE: Namespace name where por to delete is running, must start with openshift-*.
- FLAGS: Optional flags, currently only accepts --force.

```bash
ocm backplane managedjob create CEE/delete-pod -p POD_NAME: dns-default-h7l2w -p NAMESPACE=openshift-dns -p FLAGS="--force"
```

## Important Notes

- The script utilizes the `oc` command-line tool, and the user running the script should have the necessary permissions to access the cluster.
- Ensure that the required tools (`oc`) are available in the environment where the script is executed.
- The script requires pod to be bound to a replicaset. Otherwise pod cannot be deleted.
- The script provides force flag to bypass replicaset check.