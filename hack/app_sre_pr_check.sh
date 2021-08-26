#!/bin/bash

set -ex

cd $(dirname $0)/..

#pip install --user jsonschema pyyaml

#convert yaml to json
find . -name 'metadata.yaml' -exec python3 hack/yamltojson.py scripts/SREP/example/metadata.yaml  {} \;

#validate json schema
find . -name 'file:///metadata.json' -exec jsonschema --instance {} file:///hack/metadata.schema.json \;

make IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-app-sre} build
