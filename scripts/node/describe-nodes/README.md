# describe-nodes script

## Purpose

Provide the full functionality of `oc describe nodes`, as the standard `oc describe nodes` in backplane restricts access to customer workload information.
It supports 4 different modes for listing the nodes: 
* requesting all nodes
* Requesting nodes from a list
* Requesting types of nodes (master, infra, worker)
* Requesting nodes that match a selector

## Parameters and usage

Argument precedence as only one mode can be used at a time: (the first available is used)
* `NODES`: Specify the nodes to describe in the cluster separated by a ',' with no spaces
* `SELECTOR`: A Label selector to pass to oc describe nodes
* `ALL`: Describe all nodes in the cluster
* `MASTER` and/or `WORKER` and/or `INFRA`

* `DEBUG`: Enable debugging (can always be used)

### Usage with managed-scripts

Here are some examples of how to run the script with `ocm backplane managedjob`:

```bash
# Describe all nodes
ocm backplane managedjob create node/describe-nodes -p ALL=true

# Describe master and infra nodes
ocm backplane managedjob create node/describe-nodes -p MASTER=true -p INFRA=true

# Describe a list of specified nodes
ocm backplane managedjob create node/describe-nodes -p NODES="ip-10-0-137-48.us-east-2.compute.internal,ip-10-0-135-110.us-east-2.compute.internal" 

# Describe nodes with a specific label
ocm backplane managedjob create node/describe-nodes -p SELECTOR="node-role.kubernetes.io/infra"
```
