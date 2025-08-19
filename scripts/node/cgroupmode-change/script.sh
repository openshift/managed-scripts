#!/bin/bash

set -e
set -o nounset
set -o pipefail

# Default to v2
CGROUP_VERSION=${CGROUP_VERSION:-"v2"}

# Check if the cgroup version is valid
if [[ ! "${CGROUP_VERSION}" =~ ^v[12]$ ]]; then
    echo "Invalid cgroup version: ${CGROUP_VERSION}, expected 'v1' or 'v2'"
    exit 1
fi

# Update the cgroupmode field
echo "Valid cgroup version $CGROUP_VERSION, updating the cgroupmode field"
oc patch node.config.openshift.io/cluster --type=merge -p "{\"spec\": {\"cgroupMode\": \"${CGROUP_VERSION}\"}}"
