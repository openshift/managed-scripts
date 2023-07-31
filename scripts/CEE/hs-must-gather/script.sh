#!/bin/bash

set -e
set -o nounset
set -o pipefail

#define vars 
HS_HCP_MG_DIR="$DUMP_DIR/managment-cluster"
HS_DP_MG_DIR="$DUMP_DIR/hs-cluster"
HS_BINARY_PATH=" /usr/local/bin/hypershift"

 # check hypershift binary
function hasHipershiftBinary {
    echo "Checking hypershift binary available in $HS_BINARY_PATH" 
    if test -f "$HS_BINARY_PATH";
     then
        return 1
     else
        return 0
    fi
   
}

# Init must gather for Hosted controll plane
function initMustGatherforHCP {
    echo "Init must gather for management cluster namespace $HS_NAMESPACE, and data will saved to $HS_HCP_MG_DIR" 

    return 1
}

# Init must gather for hosted cluster
function initMustGatherforHC {
    echo "Init must gather for hosted cluster $CLUSTER_NAME, and data will saved to $HS_DP_MG_DIR" 

    return 1
}

# Get 
if hasHipershiftBinary "$1" ; then
    if initMustGatherforMC "$1" ; then
        initMustGatherforHC
    fi

    
else
    echo "hypershift binary not available in $HS_BINARY_PATH path" 
fi

exit 0
