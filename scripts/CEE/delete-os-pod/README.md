# Delete Openshift Pod Script

## Purpose

This script is designed to delete a pod from OpenShift cluster core namespace 

## Usage

Parameters:
- NAMESPACE: Namespace name where por to delete is running, must start with openshift-*.
- POD_NAME: Name of the pod to delete.

```bash
ocm backplane managedjob create CEE/delete-os-pod -p NAMESPACE=openshift-dns -p POD_NAME: dns-default-h7l2w
```


## Important Notes

- The script utilizes the `oc` command-line tool, and the user running the script should have the necessary permissions to access the cluster.
- Ensure that the required tools (`oc`) are available in the environment where the script is executed.