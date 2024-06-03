# Cordon/Uncordon / Drain / Reboot worker nodes

## Description

This script is responsible for performing Cordoning/Uncordoning, Draining and Rebooting operations on Worker nodes, giving the options to perform such operations as required.

## Available Options

The managed script provides the following actions:

- cordon: To cordon worker nodes
- uncordon: To uncordon worker nodes
- drain: This will cordon and then drain worker nodes
- reboot: This will cordon, drain and then reboot worker nodes

## Usage

**ATTENTION** ⚠️ This script must only be used by the MCS (Managed Cloud Services) CRU (Crew Response Unit) team.
- If you need this script to be used, contact a MCS CRU member.
- The usage of this script is audited.

### Cordon/Uncordon

```bash
ocm backplane managedjob create CEE/cordon-drain-reboot-worker-node -p WORKER="<node_name>" -p ACTION="[cordon|uncordon]"
```

### Drain

```bash
ocm backplane managedjob create CEE/cordon-drain-reboot-worker-node -p WORKER="<node_name>" -p ACTION="drain" -p DRAINMODE="<drain parameters>"
```
Ex:
```bash
ocm backplane managedjob create CEE/cordon-drain-reboot-worker-node -p WORKER="ip_x.x.x.x" -p ACTION="drain" -p DRAINMODE="--ignore-daemonsets --delete-emptydir-data --force"
```
Or, to avoid the PDB check: 
```bash
ocm backplane managedjob create CEE/cordon-drain-reboot-worker-node -p WORKER="ip_x.x.x.x" -p ACTION="drain" -p DRAINMODE="--ignore-daemonsets --delete-emptydir-data --force --disable-eviction"
```
Ref: https://docs.openshift.com/container-platform/4.15/nodes/nodes/nodes-nodes-working.html


### Reboot

```bash
ocm backplane managedjob create CEE/drain-reboot-worker-node -p WORKER="<node_name>" -p ACTION="reboot"
```
