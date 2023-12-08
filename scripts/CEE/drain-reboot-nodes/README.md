# Drain / Reboot worker nodes

## Description

This script is responsible for draining and rebooting nodes (workers only)

## Usage

**ATTENTION** ⚠️ This script must only be used by the MCS (Managed Cloud Services) CRU (Crew Response Unit) team.
- If you need this script to be used, contact a MCS CRU member.
- The usage of this script is audited.

```bash
ocm backplane managedjob create CEE/drain-reboot-nodes -p WORKER="<node_name>"
```

