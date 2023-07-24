#!/bin/bash

set -e
set -o nounset
set -o pipefail


 # Download latest hypershift version and move it to /usr/local/bin
function downloadHyperShiftBinary {
    curl -sL "$(curl -s https://api.github.com/repos/samanthajayasinghe/hypershift/releases/latest | grep browser_download_url | cut -d\" -f4)" > hypershift
    chmod +x  hypershift
    mv hypershift /usr/local/bin
}

# Init must gather for management cluster
function initMustGatherforMC {
    HS_NAMESPACE=$(oc get ns -A -o json |  jq -r '.items[] | select(.metadata.name | endswith("$CLUSTER_NAME")) | .metadata.name')
    echo "Init must gather for management cluster namespace $HS_NAMESPACE" 
    oc adm inspect namespace/$HS_NAMESPACE
}

# Init must gather for hosted cluster
function initMustGatherforHC {
    echo "Init must gather for hosted cluster $CLUSTER_NAME" 
    hypershift dump cluster --dump-guest-cluster --artifact-dir log --name $CLUSTER_NAME 
}

downloadHyperShiftBinary

initMustGatherforMC

initMustGatherforHC

exit 0
