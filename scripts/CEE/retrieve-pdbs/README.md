# Retrieve PDBs Script

## Purpose

This script is designed to retrieve information about Pod Disruption Budgets (PDBs) in OpenShift clusters. It provides details about PDBs in OpenShift namespaces, with options to retrieve information from specific namespaces, all namespaces, or only namespaces with restrictive PDBs.

## Parameters and Usage

### Usage

```bash
namespace variable options:
    - Empty/not declared:      Retrieves PDBs from all openshift* namespaces
    - --all:                   Retrieves PDBs from all namespaces
    - --restrictive:           Retrieves restrictive PDBs from all namespaces
    - <ns1>,<ns2>...:          Desired namespaces, separated by comma, to retrieve the PDBs
```

### Options

If you want to retrieve PDBs from specific namespaces, provide the namespace variable as a comma-separated list:
```bash
namespace=<namespace1>,<namespace2>,... ./script.sh
```

To retrieve PDBs from all namespaces in the cluster, use the --all option:
```bash
namespace=--all ./script.sh
```

To retrieve only restrictive PDBs from all namespaces in the cluster, use the --restrictive option:
```bash
namespace=--restrictive ./script.sh
```










### Usage with managed-scripts

For usage with managed-scripts, the options need to be passed through the `namespace` environment variable.
Some examples are:

```bash
ocm backplane managedjob create CEE/retrieve-pdbs

ocm backplane managedjob create CEE/retrieve-pdbs -p namespace="namespace1,namespace2"

ocm backplane managedjob create CEE/retrieve-pdbs -p namespace="--all"

ocm backplane managedjob create CEE/retrieve-pdbs -p namespace="--restrictive"
```

## Important Notes

- The script uses the `oc` command-line tool, and the user running the script should have the necessary permissions to access the cluster.
- This script is read-only and does not modify any resources in the cluster.
- Ensure that the required tools (`oc` & `jq`) are available in the environment where the script is executed.
