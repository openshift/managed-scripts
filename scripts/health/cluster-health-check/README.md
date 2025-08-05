# Cluster health check

## Description

This script runs many health check tasks against the cluster and prints out the results

- Cluster Operator status
- OpenShift and kube API status
- ETCD status
- MCP status
- Pending CSRs
- Nodes status
- Capacity status 
- Alerts in Firing state
- Cluster version
- Pods in failing state or with more than 10 restarts
- Restrictive PDBs
- Events (not Normal)

## Usage

```bash
ocm backplane managedjob create CEE/cluster-health-check
```

