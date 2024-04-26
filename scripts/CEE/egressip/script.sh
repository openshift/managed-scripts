#!/bin/bash

echo -e "Checking egressIP status\n"

oc get egressIP

echo "============================================================"
echo -e "\nGetting the egressIP config file\n"

oc get egressIP -o yaml

echo "============================================================"
echo -e "\nChecking nodes with the egress-assignable label\n"

oc get nodes -l k8s.ovn.org/egress-assignable

exit 0
