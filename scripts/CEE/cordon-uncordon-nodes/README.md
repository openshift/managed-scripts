# Cluster health check

## Description

This script cordons/uncordons nodes (workers only)

## Usage

```bash
ocm backplane managedjob create CEE/cordon-uncordon-nodes -p WORKER="<node_name>" -p ACTION="[cordon|uncordon]"
```
It will fail when:
- Trying to cordon/uncordon non-workers
- Trying to cordon a worker that is already cordoned
- Trying to uncordon a worker that is already uncordoned