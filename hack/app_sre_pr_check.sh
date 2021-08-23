#!/bin/bash

#set -ex

cd $(dirname $0)/..

#convert all metadata.yaml to json first
yfiles=$(find . -name 'metadata.yaml')
for f in $yfiles
do
   echo "convert $f to json"
   python3 hack/yamltojson.py $f
done
#Verify the metadata.json are valide
jfiles=$(find . -name 'metadata.json')
for f in $jfiles
do
   echo "validating the jsonschema for $f"
   if ! jsonschema --instance $f ./hack/metadata.schema.json; then
     echo "validating failed: $f"
   else
     echo "validating succeed"
   fi
done

#make IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-app-sre} build
