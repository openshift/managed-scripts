#!/bin/bash

set -ex

cd $(dirname $0)/..

pip install --user jsonschema
pip install --user  pyyaml

#convert yaml to json
python3 hack/yamltojson.py

#validate json schema
find . -name 'file:///metadata.json' -exec jsonschema --instance {} file:///hack/metadata.schema.json \;

make IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-app-sre} build
