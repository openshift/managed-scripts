# describe-nodes script

## Purpose

Provide the full functionality of `oc describe nodes`, as the standard `oc describe nodes` in backplane restricts access to customer workload information.
It supports 4 different modes for listing the nodes: 
* requesting all nodes
* Requesting nodes from a list
* Requesting types of nodes (master, infra, worker)
* Requesting nodes that match a selector

## Parameters and usage 
### Script usage

```bash
usage: describe-nodes [--all | --master | --infra | --worker | --nodes <node>,<node>,...]
  --all      : Describe all nodes in the cluster
  --master   : Describe the master nodes in the cluster
  --infra    : Describe the infra nodes in the cluster
  --worker   : Describe the worker nodes in the cluster
  --selector : A Label selector to pass to oc describe nodes
  --nodes    : Describe the listed nodes in the cluster.  The list comprises of the node name separated by a comma with no spaces
  --help

Argument precedence as only one mode can be used at a time: (the first available is used)
  --nodes
  --selector
  --all
  --master and|or --worker --and|or infra
```

### Usage with managed-scripts

For usage with managed-scripts, the options need to be passed through the `SCRIPT_PARAMETERS` environment variable. Here are some examples : 

```bash
ocm backplane managedjob create SREP/describe-node -p SCRIPT_PARAMETERS="--all"

ocm backplane managedjob create SREP/describe-node -p SCRIPT_PARAMETERS="--master --infra"

ocm backplane managedjob create SREP/describe-node -p SCRIPT_PARAMETERS="--nodes ip-10-0-137-48.us-east-2.compute.internal,ip-10-0-135-110.us-east-2.compute.internal" 

ocm backplane managedjob create SREP/describe-node -p SCRIPT_PARAMETERS="--selector node-role.kubernetes.io=infra"
```