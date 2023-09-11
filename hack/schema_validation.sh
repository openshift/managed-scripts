#!/bin/bash

#set -ex

cd $(dirname $0)/..
CONTAINER_ENGINE=$(which docker 2>/dev/null || which podman)
#convert all metadata.yaml to json first
yfiles=$(find . -name 'metadata.yaml')
for f in $yfiles
do
   echo "convert $f to json"
   if ! python3 hack/yamltojson.py $f; then
     echo "convert failed"
     exit 1
   else
     echo "convert succeed"
   fi
done
#Verify the metadata.json are valid
jfiles=$(find . -name 'metadata.json')
for f in $jfiles
do
   echo "validating the jsonschema for $f"
   if ! $CONTAINER_ENGINE run --rm -v $(pwd):/json quay.io/app-sre/managed-scripts:latest /root/.local/bin/check-jsonschema --schemafile /json/hack/metadata.schema.json /json/$f; then
     echo "validation failed: $f"
     exit 1
   fi
done