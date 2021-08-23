#!/bin/bash

set -ex

cd $(dirname $0)/..
#validate json schema
yum install gcc
pip install jsonschema

find . -name 'metadata.yaml' -exec jsonschema --instance {} hack/medata.schema.json \;

make IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-app-sre} build
