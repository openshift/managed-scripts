# OCPBUGS-34448 Workaround

## Purpose
This script is designed to remediate any nodes that are suffering from the issue described in OCPBUGS-34448.

## Usage
This script is designed to run on management clusters, passing in the internal cluster ID as a parameter. The script will then identify the nodes that are affected by the issue and remediate them.

## Create the ManagedJob
```
ocm backplane managedjob create SREP/ocpbugs-33377-workaround --params CLUSTER_ID=2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
