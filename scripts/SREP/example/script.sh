#!/bin/bash

oc -n openshift-monitoring get po

echo "This is an example"
echo "var1 is ${var1}"

exit 0
