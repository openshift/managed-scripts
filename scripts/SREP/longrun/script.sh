#!/bin/bash

oc -n openshift-monitoring get po

echo "var1 is ${var1}"

exit 0
