#!/bin/bash

set -ex

cd $(dirname $0)/..

make build-and-push
