# Cluster Operator Status

## Description

This script provides a rich summary of information concerning the status of degraded/unavailable OpenShift cluster operators:

- Basic summary (Degraded / Progressing / Available state)
- Detailed summary (Description)
- Namespace inspection (Status of all pods in each of the cluster operator's related namespaces)
- Operator logs (Most recent 15 lines of logging from the operator deployment pod)

## Usage

The script can target a specific cluster operator through the use of the `CLUSTER_OPERATOR` environment variable / backplane parameter.

If the `CLUSTER_OPERATOR` environment variable is empty or not set, the script will by default target all degraded or unavailable cluster operators.

```bash
ocm backplane managedjob create operators-lifecycle/cluster-operator-status 

or

ocm backplane managedjob create operators-lifecycle/cluster-operator-status -p CLUSTER_OPERATOR=machine-config
```

The script can adjust the time interval of logging retrieved through the use of the `OC_LOGS_SINCE` parameter. The interval can be in the form of `<duration>` followed by a unit such as `s` for seconds, `m` for minutes or `h` for hours. When specified, the last `<duration>` worth of logs are retrieved.

If no value is specified, the last 15 lines of logging are retrieved instead.

Examples:

```bash
OC_LOGS_SINCE="30s"
OC_LOGS_SINCE="30m"
```

The script can also filter what logging is retrieved through the # use of the `LOG_PATTERN` parameter. This parameter defines an 
extended regular expression passed to grep to filter logs after being returned from 'oc logs'.

Example:

```bash
LOG_PATTERN="error|warning"
```
