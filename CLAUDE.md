# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the OpenShift Dedicated managed-scripts repository, containing scripts executed by the Backplane system for cluster operations and troubleshooting.

## Development Commands

### Build and Validation
- `make build` - Build the container image with validation, shellcheck, and pyflakes
- `make validation` - Validate all metadata.yaml files against the JSON schema
- `make validation SCRIPTS="script1 script2"` - Validate specific scripts only
- `make shellcheck` - Run shellcheck on all .sh files
- `make pyflakes` - Run pyflakes on all .py files

### Testing with Backplane
Scripts are tested using the Backplane CLI:
```bash
# Connect to stage environment
ocm backplane config set url https://api.stage.backplane.openshift.com
ocm backplane login <stage-cluster-id>

# Test a script
ocm backplane testjob create [-p var1=val1]

# Check status and logs
ocm backplane testjob get <job-id>
ocm backplane testjob logs <job-id>
```

## Architecture and Structure

### Script Organization
Scripts are organized by team/category under `scripts/`:
- `alerting/` - Alerting and monitoring scripts
- `config/` - Configuration management
- `health/` - Health checking utilities
- `kafka/` - Kafka-specific operations
- `lib/` - Shared libraries and utilities
- `maintenance/` - Maintenance operations
- `networking/` - Network troubleshooting
- `node/` - Node operations
- `operators-lifecycle/` - Operator management
- `security/` - Security-related scripts
- `storage-registry/` - Storage and registry operations
- `troubleshooting/` - General troubleshooting

### Script Structure
Each script directory must contain:
- `script.sh` or `script.py` - The executable script
- `metadata.yaml` - Script metadata conforming to `hack/metadata.schema.json`
- Optional: `README.md` - Additional documentation

### Metadata Schema
The `metadata.yaml` file defines:
- Script metadata (name, description, author)
- Language (bash or python)
- RBAC permissions required
- Allowed groups (CEE, SREP, etc.)
- Environment variables
- Customer data access declaration
- Cluster version requirements

### Container Environment
Scripts run in a UBI8-based container with pre-installed tools:
- OpenShift CLI (`oc`)
- AWS CLI (`aws`)
- OCM CLI (`ocm`)
- OSDCTL (`osdctl`)
- Hypershift CLI (`hypershift`)
- YQ (`yq`)
- Standard utilities (jq, ssh, python3.11)

## Release Process

- **Staging**: Automatically deploys from `main` branch
- **Production**: Released every 3 weeks
- For urgent production releases, contact @managed-scripts in #sd-ims-backplane

## Key Files

- `hack/metadata.schema.json` - JSON schema for metadata validation
- `hack/schema_validation.sh` - Validation script for metadata files
- `template/` - Template for new script creation
- `Dockerfile` - Container build definition with all required tools