# cgroupMode-change


## Purpose

The script is used to change the cgroups version on the node by updating the spec.cgroupMode in cluster node.config.openshift.io object. This changes the version of cgroups used on the nodes of the cluster.

## Parameters and usage 
```bash
CGROUP_VERSION:
    - Empty/not declared:       Uses "v2"
    - "v1":                     cgroups v1, only available on OpenShift <= 4.18
    - "v2":                     cgroups v2
```


## Usage

### Usage with managed-scripts
Changing the cgroupMode field will trigger a change in machine config and roll out the new config by RESTARTING ALL NODES one by one per MachineConfigPool

To migrate to v2 run, or leave the CGROUP_VERSION unset

```bash
ocm backplane managedjob create node/cgroupmode-change -p CGROUP_VERSION="v2"

```

While migrating back to v1 is strongly NOT RECOMMENDED and NOT SUPPORTED to migrate to v1 run

```bash
ocm backplane managedjob create node/cgroupmode-change -p CGROUP_VERSION="v1"

```

After about 30s the machine-configs will be updated and a new rollout will start.

You can follow the migration progress by checking the progress of the machine-config operator or the MachineConfigPools
```bash
oc get mcp
NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
master   rendered-master-21539ad2565124515dc5b20e818dad37   False     True       False      3              0                   0                     0                      7h59m
worker   rendered-worker-57e8b8126cd62c38b25473d527853fc5   False     True       False      6              0                   0                     0                      7h59m
```

The migration is complete when READYMACHINECOUNT for all MachineConfigPools is equal to MACHINECOUNT.