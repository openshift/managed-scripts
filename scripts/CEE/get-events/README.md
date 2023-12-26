# Get Events Script

## Purpose

This script is designed to retrieve events in OpenShift clusters across different namespaces.

## Parameters and Usage

### Usage

```bash
namespace variable options:
    - Empty/not declared:      Retrieves events from all OpenShift* namespaces
    - --all:                   Retrieves events from all namespaces
    - <ns1>,<ns2>...:          Specifies desired namespaces, separated by commas, to obtain events
```

### Options

If you want to get the events from specific namespaces, provide the namespace variable as a comma-separated list:
```bash
namespace=<namespace1>,<namespace2>,... ./script.sh
```

To retrieve events from all namespaces in the cluster, use the --all option:
```bash
namespace=--all ./script.sh
```

### Usage with managed-scripts

For usage with managed-scripts, the options need to be passed through the `namespace` environment variable.
Some examples are:

```bash
ocm backplane managedjob create CEE/get-events

ocm backplane managedjob create CEE/get-events -p namespace="namespace1,namespace2"

ocm backplane managedjob create CEE/get-events -p namespace="--all"
```

## Important Notes

- The script utilizes the `oc` command-line tool, and the user running the script should have the necessary permissions to access the cluster.
- This script is read-only and does not modify any resources in the cluster.
- Ensure that the required tools (`oc` & `jq`) are available in the environment where the script is executed.
