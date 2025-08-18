# osdctl Network Verifier

This managed script runs network egress verification in pod mode using the pre-installed `osdctl` binary to validate that a ROSA/OSD cluster can reach all required external URLs necessary for full support.

## Overview

The script uses [osd-network-verifier](https://github.com/openshift/osd-network-verifier)'s pod mode to perform network egress testing from within the actual cluster environment. This provides more accurate results compared to traditional cloud instance verification because:

- Tests are performed from within the actual cluster network environment
- Works correctly with both public and private subnets
- Doesn't require NAT gateway access like traditional probe instances
- Validates the exact network path that cluster workloads would use

## What it does

1. **Platform Detection**: Automatically detects the cloud provider (AWS or GCP) from cluster infrastructure.  Note that a flag
must be passed for HCP or Zero-Egress platform types
2. **Region Detection**: Automatically detects the region for AWS-based clusters (classic, HCP, or HCP zero egress)
3. **Pod-based Verification**: Runs network verification using Kubernetes Jobs in the `openshift-network-diagnostics` namespace
4. **Service Log Skip**: Uses the `--skip-service-log` flag to prevent automatic service log generation
5. **Binary Usage**: Uses the pre-installed `osdctl` binary from the container image

## Usage

### Basic Usage

```bash
# Run via OCM backplane (AWS classic clusters)
ocm backplane managedjob create networking/osdctl-network-verifier

# Check job status
ocm backplane managedjob list

# View job logs
ocm backplane managedjob logs <job-id>
```

### Platform-Specific Usage

The script supports different platform configurations via the `SCRIPT_PARAMETERS` environment variable:

```bash
# AWS Classic clusters (default - no parameters needed)
ocm backplane managedjob create networking/osdctl-network-verifier

# HCP (Hosted Control Plane) clusters
ocm backplane managedjob create networking/osdctl-network-verifier -p SCRIPT_PARAMETERS="--hcp"

# HCP clusters with zero egress configuration
ocm backplane managedjob create networking/osdctl-network-verifier -p SCRIPT_PARAMETERS="--zero-egress"

# Show help and available parameters
ocm backplane managedjob create networking/osdctl-network-verifier -p SCRIPT_PARAMETERS="--help"
```


## RBAC Permissions

The script requires the following permissions:

### Cluster-scoped permissions:
- **Infrastructure**: get (for platform and region detection)

### Namespace-scoped permissions (`openshift-network-diagnostics` only):
- **Jobs**: get, list, create, delete, watch (for verification jobs)
- **Pod logs**: get (for debugging verification results)

### Platform and Region Detection

The script automatically detects the cloud provider and platform type:

1. **Cloud Provider Detection**: Queries the cluster infrastructure object to determine if the cluster is running on AWS or GCP
2. **AWS Platform Types**: 
   - **Classic** (default): Standard ROSA/OSD clusters
   - **HCP**: Hosted Control Plane clusters (specified with `--hcp` flag)
   - **Zero Egress**: HCP clusters with zero egress configuration (specified with `--zero-egress` flag)
3. **Region Detection**: For AWS-based clusters, automatically detects the region from cluster infrastructure
4. **GCP Clusters**: Platform type is set to `gcp-classic` (region detection not required for GCP)

### Pod Mode Verification

Pod mode creates Kubernetes Jobs that run verification containers within the cluster. This approach:
- Uses the cluster's actual network configuration
- Tests egress through the same network path as cluster workloads
- Provides accurate results for both public and private subnet configurations
- Doesn't require external cloud provider credentials

## Related Documentation

- [ROSA Network Prerequisites](https://docs.openshift.com/rosa/rosa_install_access_delete_clusters/rosa_getting_started_iam/rosa-aws-prereqs.html#osd-aws-privatelink-firewall-prerequisites_prerequisites)
- [osd-network-verifier GitHub Repository](https://github.com/openshift/osd-network-verifier)
- [osdctl GitHub Repository](https://github.com/openshift/osdctl) 