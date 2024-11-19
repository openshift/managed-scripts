# get-haproxy-config

This script prints the HAProxy configuration from one of the router pods in an
OpenShift cluster.


### Usage

The script optionally accepts the name of a pod in the openshift-ingress
namespace as an argument; when run with no arguments, the first router pod
from the default ingress controller will be used.

**Get the contents of haproxy.config from the first router pod**

```bash
ocm backplane managedjob create CEE/get-haproxy-config
```

**Get the contents of haproxy.config from a specific pod**:

```bash
ocm backplane managedjob create CEE/get-haproxy-config -p ROUTER=<pod_name>
```


### Important Notes

- The script utilizes the `oc` command-line tool, and the user running the script should have the necessary permissions to access the cluster.
- This script is read-only and does not modify any resources in the cluster.
