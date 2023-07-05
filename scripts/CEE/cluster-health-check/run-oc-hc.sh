#!/bin/bash
# Download the lastest release of oc-hc and runs it 
set -eou pipefail

# Download latest version and move it to /usr/local/bin
curl -sL $(curl -s https://api.github.com/repos/givaldolins/openshift-cluster-health-check/releases/latest | grep browser_download_url | cut -d\" -f4 | grep -E 'linux-amd64.tar.gz$') | tar zx
mv oc-hc /usr/local/bin

# Run check
oc hc cluster

