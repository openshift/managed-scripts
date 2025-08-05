# Machine Autoscaler Data Collector Script

## Purpose

This script is designed to collect and retrieve the machine autoscaler data from OpenShift cluster.

## Usage

```bash
ocm backplane managedjob create CEE/machine-autoscaler-inspect
```

## Important Notes

- The script utilizes the `oc` command-line tool, and the user running the script should have the necessary permissions to access the cluster.
- This script is read-only and does not modify any resources in the cluster.
- Ensure that the required tools (`oc`) are available in the environment where the script is executed.
