#!/bin/bash

set -ex

cd $(dirname $0)/..

# TODO: Invoke this make target directly from appsre ci-int and scrap this file
make build-push
