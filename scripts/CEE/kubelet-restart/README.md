# Restart Kubelet on Node

This will script will restart kubelet on Node. Scenarios where a restart might be required:
- OpenShift related pod stuck in containerUnknown Status
- Certain bugs require container restart on Master Nodes. [Eg. https://access.redhat.com/solutions/6976343 ] 

- Add the node name as parameter.

Example:
```
ocm backplane managedjob create CEE/restart-kubelet -p NODE="$NODE_NAME"
```

