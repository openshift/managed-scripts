# NODE DRAIN REBOOT

## Purpose

This script will help drain and reboot node without the need of having elevation privileges

## Create the ManagedJob to reboot and drain the node
```
ocm backplane managedjob create node/node-drain-reboot -p node=<node-name>
```
