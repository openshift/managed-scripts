#!/bin/bash

set -ex

cd $(dirname $0)/..

make IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-app-sre} build
