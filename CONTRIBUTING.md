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

The `ocm backplane testjob create`, `get`, and `logs` commands are deprecated. Use `ocm backplane testjob render` instead, which generates the Kubernetes YAML (ServiceAccount, RBAC, and Pod) for your draft script locally — no backplane API call is made. You then apply it directly with `oc` on a non-production cluster where you have `cluster-admin` access, and use plain `oc` to watch, inspect, and clean up.

1. **Log In to a Non-Production Cluster**
   - Use a normal IDP login to a non-production cluster where you have `cluster-admin` access (no `ocm backplane login` needed).
   ```sh
   oc login <cluster-api-url>
   ```

2. **Render the Test Job YAML**
   - Run this from the script directory (which contains `metadata.yaml` and the script).
   ```sh
   cd scripts/CEE/new-script
   ocm backplane testjob render [-p var1=val1] > test-job.yaml
   ```
   Useful flags:
   - `-p`/`--params` - script parameter, repeatable.
   - `-s`/`--source-dir` - script source directory (defaults to the current directory).
   - `-i`/`--base-image-override` - override the base image (defaults to the latest managed-scripts image resolved from GitHub).
   - `-o`/`--output` - write to a file instead of stdout.

3. **Review and Apply the YAML**
   ```sh
   oc apply -f test-job.yaml
   ```

4. **Check Job Status**
   ```sh
   oc -n openshift-backplane-managed-scripts get pods
   ```

5. **View Logs**
   ```sh
   oc -n openshift-backplane-managed-scripts logs <pod-name>
   ```

6. **Clean Up**
   ```sh
   oc delete -f test-job.yaml
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
