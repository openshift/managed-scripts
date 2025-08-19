# RETRY PRUNING CRON JOB

## Purpose

This script will help re-run the jobs which are failed in `openshift-sre-pruning` namespace

## Usage
This script will detect and delete the failed jobs that are running in the `openshift-sre-pruning` namespace and causing pruning-cron-job error, deleting will help recreate new jobs and possibly resolve the alert, and if not SREs can investigate and find the root cause.

## Create the ManagedJob to restart the failed jobs
```
ocm backplane managedjob create storage-registry/retry-failed-pruning-cronjob 
```