#!/bin/bash
# This script is adopt from internal SOP.
# Original contributors: ravitri, dastergon

ETCD=$(oc get pods -l k8s-app=etcd -n openshift-etcd -o jsonpath='{.items[*].metadata.name}' | awk '{ print $1 }')

echo
echo ">> etcdctl endpoint status"
oc exec "$ETCD" -n openshift-etcd -c etcdctl -- sh -c "etcdctl endpoint status -w table"

echo
echo ">> etcdctl endpoint health"
oc exec "$ETCD" -n openshift-etcd -c etcdctl -- sh -c "etcdctl endpoint health -w table"

echo
echo ">> etcdctl member list"
oc exec "$ETCD" -n openshift-etcd -c etcdctl -- sh -c "etcdctl member list -w table"

exit 0
