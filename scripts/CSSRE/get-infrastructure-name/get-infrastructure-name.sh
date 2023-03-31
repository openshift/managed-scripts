#!/bin/bash

set -euo pipefail

oc get infrastructure cluster -o json | jq .status.infrastructureName
