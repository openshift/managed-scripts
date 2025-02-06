# Validate Pull Secret

## Description

The `validate_pull_secret` managed script compares the pull secret deployed on the cluster with the pull secret stored in OCM. The script automates the following processes:

1. Obtains the ID of the current OpenShift cluster.
2. Obtains the username of the associated with the current Openshift cluster.
3. Retrieves the pull-secret from OCM
4. Retrieves the pull-secret from the openshift-config namespace located on the current Openshift cluster.
5. Compares the secret the OCM pull-secret with the ones in the Openshift pull-secret.
6. Fails if a secret in the OCM pull-secret differs or it's missing from the Openshift pull-secret

## Usage

```bash
ocm backplane managedjob create SREP/validate-pull-secret
```
