# Contributing to Backplane-Managed Scripts 

This document presents some guidleines and best-practices to remember while contributing to managed-scripts.

## Overview
Managed-Scripts enable backplane users to execute predefined scripts while adhering to the permissions defined within the script's scope.

## Terminology

### Managed Script
A script file and its associated metadata file, stored in the managed-scripts repository.

### Managed Job
A running instance of the Managed Script in an OSD/ROSA cluster.

## Prerequisites

Before creating, testing, or deploying new scripts, ensure you have the following:

1. VPN connectivity
2. [OCM CLI Binary](https://github.com/openshift-online/ocm-cli)
3. [Backplane CLI Binary](https://source.redhat.com/groups/public/sre/wiki/setup_backplane_cli)
4. Access to the [Stage API](https://api.stage.backplane.openshift.com)

All pre-existing scripts can be found [here](https://github.com/openshift/managed-scripts/tree/main/scripts) for reference.

## Creating a New Script

1. **Fork the Managed Scripts Repository**
   - Create your fork of the [Managed Scripts Repository](https://github.com/openshift/managed-scripts).

2. **Create a new branch**
   - Do not use the `main` or `master` branch for PRs.
   - Name the branch based on the JIRA card, feature or subject matter.
   - Refer to [GitHub's guide on creating branches](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-and-deleting-branches-within-your-repository).

3. **Clone the Repository**
   ```sh
   git clone https://github.com/<git_user>/managed-scripts.git
   ```

4. **Create a New Folder for the Script**
   ```sh
   cd <path-to-folder>/managed-scripts/scripts/CEE
   mkdir -p new-script
   ```

5. **Add Metadata File (`metadata.yaml`)**
   - Follow the [metadata schema](https://github.com/openshift/managed-scripts/blob/main/hack/metadata.schema.json).
   - Example metadata file: [etcd-health-check](https://github.com/openshift/managed-scripts/blob/main/scripts/CEE/etcd-health-check/metadata.yaml).
   - Define `allowedGroups` (e.g., `CEE`, `SREP`) with applicable RBAC permissions.

6. **Create the Script File (`script.sh`)**
   ```sh
   tree new-script
   new-script
   ├── metadata.yaml
   └── script.sh
   ```

## Testing the Script

1. **Ensure You Are Using the Stage API**
   ```sh
   ocm backplane config set url https://api.stage.backplane.openshift.com
   ocm backplane config get url
   ```
   Output:
   ```
   url: https://api.stage.backplane.openshift.com
   ```

2. **Connect to a Stage Cluster**
   ```sh
   ocm backplane login <stage-cluster-id>
   ```

3. **Run a Test Job**
   ```sh
   ocm backplane testjob create [-p var1=val1]
   ```
   Example Output:
   ```
   Test job openshift-job-dev-7m755 created successfully    
   Run "ocm backplane testjob get openshift-job-dev-7m755" for details
   Run "ocm backplane testjob logs openshift-job-dev-7m755" for job logs
   ```

4. **Check Job Status**
   ```sh
   ocm backplane testjob get openshift-job-dev-7m755
   ```
   Example Output:
   ```
   TestId: openshift-job-dev-7m755, Status: Succeeded
   ```

5. **View Logs**
   ```sh
   ocm backplane testjob logs openshift-job-dev-7m755
   ```

## Deploying the Script to Production

- **PR Review & Merge Process**
  - Once your changes are well tested and pushed, create a PR containing a brief information about the script's utility and usage.
  - The script must be reviewed and approved by the SRE team.
  - Use Slack channel `#sre-operators` or `#sd-ims-backplane` and tag `@managed-scripts` for discussions.
    
- **Promote the script using ops-sop/v4/util/promote-managed-scripts.sh

- **Validate Production Deployment**
  1. Connect to the [Backplane Production API](https://api.backplane.openshift.com).
  2. Log in to a production cluster.
  3. List available managed scripts:
     ```sh
     ocm backplane script list
     ```
