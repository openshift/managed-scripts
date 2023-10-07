# Cordon / Uncordon worker nodes

## Description

This script cordons/uncordons nodes (workers only)

## Usage

**ATTENTION** ⚠️ This script must only be used by the MCS (Managed Cloud Services) CRU (Crew Response Unit) team.
- If you need this script to be used, contact a MCS CRU member.
- The usage of this script is audited.

```bash
ocm backplane managedjob create CEE/cordon-uncordon-nodes -p WORKER="<node_name>" -p ACTION="[cordon|uncordon]"
```
It will fail when:
- Trying to cordon/uncordon non-workers
- Trying to cordon a worker that is already cordoned
- Trying to uncordon a worker that is already uncordoned
