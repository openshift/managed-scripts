#!/bin/bash

set -e
set -o nounset
set -o pipefail

## validate input
if [[ -z "$node" ]]
then
    echo 'Variable node cannot be blank please try again'
    exit 1
fi

if ! [[ "$node" =~ ^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$ ]]
then
    echo "The node name must be valid hostname"
    exit 1
fi

## get the journal of that node
oc adm node-logs $node

exit 0
