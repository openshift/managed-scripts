#!/bin/bash

set -o nounset
set -o pipefail

oc get secret pull-secret -n openshift-config -o json | jq -r '."data".".dockerconfigjson"' | base64 -d | jq -r '."auths"."cloud.openshift.com"."email"'

exit 0
