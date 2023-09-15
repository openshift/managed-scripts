# Delete-worker-node script

## Purpose

The script is used to delete a worker node that might be stuck for some reason and the customer is experiencing any business lost so the fastest solution is to delete the node and let the cluster create a new healthy one.

The script should be used as a last resource since it can cause some issues due the fact that we are deleting the machine.

## Parameters and usage 

### Usage with managed-scripts
For usage with managed-scripts, there are two options that has to be passed through as environment variables. 

#### Alert Options
The `NODE` environment variable which is the name of the node and the `MACHINE` environment variable which is the name of the machine associated to that node:


```bash
ocm backplane managedjob create CEE/delete-worker-node -p NODE="<node name>" -p MACHINE="<machine name>"

```

#### WARNING

This is a script with write access that can cause some issue on the customer workloads so we need explicit confirmation on the case to remove the node and let them aware that if there are workloads with only one replica on that node or storage attached to that specific node, it might cause some disruption.


Worker nodes are managed by the machine-api operator, based on the Machine objects that exist. In this case, if we need to delete/recreate a worker node, we can delete it's associated machine object which will trigger the machine-api operator to deprovision/terminate the existing node, and then recreate a new one as there will be too few for the MachineSet.

1.    Retrieve the list of nodes and their associated `Machine` names:

```bash
$ oc get nodes --output="custom-columns=NODE NAME:.metadata.name,MACHINE NAME:.metadata.annotations.machine\.openshift\.io/machine"
NODE NAME                                    MACHINE NAME
ip-10-0-128-124.us-west-2.compute.internal   openshift-machine-api/cblecker-sep10-lvs68-worker-us-west-2a-qpmdb
ip-10-0-134-38.us-west-2.compute.internal    openshift-machine-api/cblecker-sep10-lvs68-worker-us-west-2a-v75rk
ip-10-0-135-214.us-west-2.compute.internal   openshift-machine-api/cblecker-sep10-lvs68-master-2
ip-10-0-138-80.us-west-2.compute.internal    openshift-machine-api/cblecker-sep10-lvs68-master-1
ip-10-0-141-136.us-west-2.compute.internal   openshift-machine-api/cblecker-sep10-lvs68-worker-us-west-2a-2nqhm
ip-10-0-141-189.us-west-2.compute.internal   openshift-machine-api/cblecker-sep10-lvs68-master-0
ip-10-0-142-74.us-west-2.compute.internal    openshift-machine-api/cblecker-sep10-lvs68-worker-us-west-2a-9jzjg

```

2. Retrieve the list of machines that are backed by `MachineSets`:

```bash
$ oc get machines -n openshift-machine-api -l machine.openshift.io/cluster-api-machineset
NAME                                           INSTANCE              STATE     TYPE        REGION      ZONE         AGE
cblecker-sep10-lvs68-worker-us-west-2a-2nqhm   i-02947edb0eba38339   running   m5.xlarge   us-west-2   us-west-2a   2d22h
cblecker-sep10-lvs68-worker-us-west-2a-9jzjg   i-0f34db88405c7ddfb   running   m5.xlarge   us-west-2   us-west-2a   2d22h
cblecker-sep10-lvs68-worker-us-west-2a-qpmdb   i-0f6308f9d0a04c8b9   running   m5.xlarge   us-west-2   us-west-2a   2d22h
cblecker-sep10-lvs68-worker-us-west-2a-xnc9t   i-0e6376584900a732f   running   m5.xlarge   us-west-2   us-west-2a   2d22h
```

3. Match the `Machine` to the node you wish to delete. If the node you wish to delete doesn't show up in this list, you will not be able to delete it with this method as a `MachineSet` will not recreate it.