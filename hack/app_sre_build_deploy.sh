#!/bin/bash

set -ex

cd $(dirname $0)/..

make skopeo-push
