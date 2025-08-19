# ETCD Complete Health Check

## Description

This script provides a rich summary of etcd concerning the health of OpenShift cluster etcd-operators:

- Basic summary (Avaiable and Unhealthy Nodes)
- Detailed summary (Member List, Endpoint Status and Health)
- Namespace inspection (Status of all pods in each of the cluster operator's related namespaces)
- Etcd logs (Most recent 48h logs)

## Usage
This script creates a job that runs in the namespace `openshift-backplane-managed-scripts`, which inside the logs of the job pod has the result of the health check.

## Create the job to run the health check
ocm backplane managedjob create health/etcd-complete-health-check