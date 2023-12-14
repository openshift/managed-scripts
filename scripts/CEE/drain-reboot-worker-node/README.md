# Drain / Reboot worker nodes

## Description

This script is responsible for draining and rebooting nodes (workers only).

## Steps It Takes

1. Check if the provided node is a Worker node;
2. If Yes, it starts draining the node with the option to bypass any PDB which may block the process;
3. After draining, it reboots the node;
4. There is a function which checks the node reboot. A timeout of 300 seconds has been implemented to stop the process in case any issue is faced during the reboot process;
5. Once the node is rebooted, it will stay as "Ready,SchedulingDisabled". It is required, after that, to run the managed script to uncordon the node [cordon-uncordon-nodes](https://github.com/openshift/managed-scripts/tree/main/scripts/CEE/cordon-uncordon-nodes).

## Usage

**ATTENTION** ⚠️ This script must only be used by the MCS (Managed Cloud Services) CRU (Crew Response Unit) team.
- If you need this script to be used, contact a MCS CRU member.
- The usage of this script is audited.

```bash
ocm backplane managedjob create CEE/drain-reboot-worker-node -p WORKER="<node_name>"
```

