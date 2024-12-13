# Check for missing API Services Script

## Purpose

This script prints the missing APIServices from OpenShift cluster if any.

## Usage

```bash
ocm backplane managedjob create CEE/check-missing-apis
```


## Important Notes

- The script utilizes the `oc` command-line tool, and the user running the script should have the necessary permissions to access the cluster.
- This script is read-only and does not modify any resources in the cluster.
- Ensure that the required tools (`oc`) are available in the environment where the script is executed.
