#!/bin/bash
# Originally from ops-sop.git/v4/utils/tsdb-status

TOKEN="$(oc -n openshift-monitoring sa get-token prometheus-k8s)"
URL="https://$(oc -n openshift-monitoring get routes prometheus-k8s -o=jsonpath='{.spec.host}')/api/v1/status/tsdb"

curl -G -s -k -H "Authorization: Bearer $TOKEN" "$URL"
