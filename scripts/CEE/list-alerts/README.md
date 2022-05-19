# list-alerts script

## Purpose

The script is used to list ongoing alerts and silences for a given cluster.
It allows filtering by severity (warning or critical) and alert state (firing or pending).
Pending alerts are for conditions which are currently triggered but for less than the configured threshold duration (and hence, did not alert yet). It also provides the option to check alerts in one or more Prometheus instances by passing in a list of namespaces running Prometheus.

## Parameters and usage 
### Script usage
#### Alert Options
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

#### Host Options
```bash
# Print out the namespace and host name of Prometheus instances on the cluster
usage: script.sh --hosts
```

### Usage with managed-scripts
For usage with managed-scripts, there are two options that can be passed through as environment variables. Each option can be used individually or together:

#### Alert Options
The `SCRIPT_PARAMETERS` environment variable which is a list of alert options:

```bash
ocm backplane managedjob create CEE/list-alerts -p SCRIPT_PARAMETERS="--warning-only --pending-only"

ocm backplane managedjob create CEE/list-alerts -p SCRIPT_PARAMETERS="--all-states" 

ocm backplane managedjob create CEE/list-alerts -p SCRIPT_PARAMETERS="--list-silences"

# [Default] This will list all the firing alerts (warning and critical)
ocm backplane managedjob create CEE/list-alerts 
```

#### Host Options
The `NAMESPACES` environment variable which is a list of namespaces containing a Prometheus instance that you want to check the alerts in:
```bash
# Checks Prometheus the application-services-observability namespace only
ocm backplane managedjob create CEE/list-alerts -p NAMESPACES="application-services-observability"

# Checks Prometheus in the application-services-observability and user-observability namespaces
ocm backplane managedjob create CEE/list-alerts -p NAMESPACES="application-services-observability user-observability"

# [Default] Checks the openshift-monitoring Prometheus instance only
ocm backplane managedjob create CEE/list-alerts 
```