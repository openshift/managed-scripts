#!/bin/bash
# Originally from ops-sop.git/v4/utils/tsdb-status

curl -G -s -k -H "Authorization: Bearer $(oc -n openshift-monitoring sa get-token prometheus-k8s)" "https://$(oc -n openshift-monitoring get routes prometheus-k8s -o=jsonpath='{.spec.host}')/api/v1/status/tsdb"
