SHELL := /usr/bin/env bash

# Include shared Makefiles
include project.mk
include standard.mk

# Extend Makefile after here

.PHONY: build-push
build-push:
	hack/app_sre_build_push.sh $(IMAGE_URI_VERSION)
