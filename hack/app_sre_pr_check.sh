#!/bin/bash

set -ex

cd $(dirname $0)/..

 #validate json schema

pip install --user jsonschema
pip install --user  pyyaml
pip install --user ruamel.yaml
pwd
python3 hack/build/yamltojson.py
find . -name 'metadata.json' -exec jsonschema --instance {} hack/metadata.schema.json \;

make IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-app-sre} build
