# Collect verbose logs from cluster-autoscaler pod

## Description

This script is responsible for collecting verbose logs (logVerbosity=6) from cluster-autoscaler pods

## Steps It Takes

1. The script checks the current verbosity of "default" cluster autoscaler and stores it in a variable
2. Updates the value for logVerbosity to 6
3. Collects the verbose logs for 6 minutes
4. Filters the collected logs by node-names and displays the filtered logs.
5. Reverts the value of logVerbosity.

## Usage

**ATTENTION** ⚠️ This script must only be used by the MCS (Managed Cloud Services) CRU (Crew Response Unit) team.
- If you need this script to be used, contact a MCS CRU member.
- The usage of this script is audited.

```bash
ocm backplane managedjob create troubleshooting/collect-verbose-ca-logs"
```

