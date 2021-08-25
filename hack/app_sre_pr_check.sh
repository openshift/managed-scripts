#!/bin/bash

set -ex

cd $(dirname $0)/..
pwd
#validate json schema

#pip install --user jsonschema
#pip install --user  pyyaml
python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' scripts/SREP/example/metadata.yaml > scripts/SREP/example/metadata.json
find . -name 'metadata.json' -exec jsonschema --instance {} hack/metadata.schema.json \;

#make IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-app-sre} build
