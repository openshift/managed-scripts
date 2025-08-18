# Check Tech Preview Features

## Description
This script is used to check if the cluster has any tech preview features enabled.

It checks for any feature sets in the cluster, if found then it lists the feature set along with the feature gates enabled additionally apart from the default enabled feature gates.

## Terminology
- **Feature Set**:  A feature set is a collection of OpenShift Container Platform features that are not enabled by default.
- **Feature Gate**: A cluster administrator can use feature gates to enable features that are not part of the default set of features. This is done by editing the `FeatureGate` custom resource.

### Usage
```bash
# Create a managed job
ocm backplane managedjob create config/check-tech-preview-features

# Check the logs
ocm backplane managedjob logs <Job_Id>
```