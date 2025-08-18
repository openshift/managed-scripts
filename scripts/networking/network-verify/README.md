# osdctl Network Verifier

This managed script downloads the latest `osdctl` binary and runs network egress verification in pod mode to validate that a ROSA/OSD cluster can reach all required external URLs necessary for full support.

## Overview

The script uses [osd-network-verifier](https://github.com/openshift/osd-network-verifier)'s pod mode to perform network egress testing from within the actual cluster environment. This provides more accurate results compared to traditional cloud instance verification because:

- Tests are performed from within the actual cluster network environment
- Works correctly with both public and private subnets
- Doesn't require NAT gateway access like traditional probe instances
- Validates the exact network path that cluster workloads would use

## What it does

1. **Downloads Latest Binary**: Automatically downloads the latest `osdctl` binary from GitHub releases
2. **Region Detection**: Automatically detects the AWS region from cluster infrastructure or metadata service
3. **Pod-based Verification**: Runs network verification using Kubernetes Jobs in the `openshift-network-diagnostics` namespace
4. **Service Log Skip**: Uses the `--skip-service-log` flag to prevent automatic service log generation
5. **Cleanup**: Automatically cleans up temporary files after completion

## Usage

```bash
# Run via OCM backplane
ocm backplane managedjob create networking/osdctl-network-verifier

# Check job status
ocm backplane managedjob list

# View job logs
ocm backplane managedjob logs <job-id>
```

## Requirements

- The script must run with a ServiceAccount that has the necessary RBAC permissions (automatically handled by managed scripts framework)
- Internet access to download the osdctl binary from GitHub
- Cluster must be a ROSA or OSD cluster for verification to be meaningful

## RBAC Permissions

The script requires the following cluster-level permissions:

- **Pods**: get, list, create, delete, watch (for verification pods)
- **Namespaces**: get, list, create, delete, watch (for verification namespace)
- **Jobs**: get, list, create, delete, watch (for verification jobs)
- **Infrastructure**: get (for region detection)
- **Pod logs**: get (for debugging verification results)

## Technical Details

### Region Detection

The script attempts to detect the AWS region in the following order:
1. From cluster infrastructure object (`config.openshift.io/v1/Infrastructure`)
2. From AWS metadata service (if running on AWS)
3. Falls back to `us-east-1` as default

### Pod Mode Verification

Pod mode creates Kubernetes Jobs that run verification containers within the cluster. This approach:
- Uses the cluster's actual network configuration
- Tests egress through the same network path as cluster workloads
- Provides accurate results for both public and private subnet configurations
- Doesn't require external cloud provider credentials

### Error Handling

The script includes comprehensive error handling for:
- Network connectivity issues during binary download
- Kubernetes API access problems
- Region detection failures
- Verification job failures

## Troubleshooting

### Common Issues

1. **Binary Download Fails**: Check internet connectivity and GitHub API access
2. **Region Detection Fails**: Manually specify region if auto-detection doesn't work
3. **Pod Creation Fails**: Verify RBAC permissions and namespace access
4. **Verification Fails**: Review pod logs for specific egress failures

### Debugging

- Script runs with `--debug` flag for verbose osdctl output
- All script actions are logged with INFO/WARN/ERROR prefixes
- Verification pod logs are available via standard Kubernetes logging

## Security Considerations

- Script downloads and executes external binary (latest osdctl from GitHub)
- Requires cluster-wide RBAC permissions for pod and job management
- Does not access customer data (`customerDataAccess: false`)
- Uses temporary file cleanup to avoid leaving artifacts

## Related Documentation

- [ROSA Network Prerequisites](https://docs.openshift.com/rosa/rosa_install_access_delete_clusters/rosa_getting_started_iam/rosa-aws-prereqs.html#osd-aws-privatelink-firewall-prerequisites_prerequisites)
- [osd-network-verifier GitHub Repository](https://github.com/openshift/osd-network-verifier)
- [osdctl GitHub Repository](https://github.com/openshift/osdctl) 