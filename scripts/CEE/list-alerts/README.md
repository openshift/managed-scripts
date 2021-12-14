# list-alerts script

## Purpose

The script is used to ease liar on-going alerts and silence for a given cluster.
It allows to filter by severity (warning or critical) and alert state (firing or pending).
Pending alerts are for conditions which are currently triggered but for less than the configured threshold duration (and hence, did not alert yet). 

## Parameters and usage 
### Script usage

```bash
usage: script.sh [--warning-only|--critical-only] [--firing-only|--pending-only|--all-states] | --list-silences
Default : Retrieved warning and critical alerts in Firing state
  --warning-only: print warning alerts only
  --critical-only: print critical alerts only
  --firing-only: print only firing alert state (default)
  --pending-only: print only pending alert state
  --all-states: print firing and pending alerts
  --list-silences: print all active silences
```

`--firing-only` , `--pending-only` and `--all-states` are mutually exclusive. 
The same way, `--warning-only` and `--critical-only` are mutually exclusive. 

### Usage with managed-scripts

For usage with managed-scripts, the options need to be passed through the `SCRIPT_PARAMETERS` environment variable. Here are some examples : 

```bash
ocm backplane managedjob create CEE/list-alerts -p SCRIPT_PARAMETERS="--warning-only --pending-only"

ocm backplane managedjob create CEE/list-alerts -p SCRIPT_PARAMETERS="--all-states" 

ocm backplane managedjob create CEE/list-alerts -p SCRIPT_PARAMETERS="--list-silences"

# This will list all the firing alerts (warning and critical)
ocm backplane managedjob create CEE/list-alerts 
```