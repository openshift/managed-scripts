IMAGE_REGISTRY?=quay.io
IMAGE_REPOSITORY?=app-sre
IMAGE_NAME?=managed-scripts

# Generate version and tag information from inputs
IMAGE_VERSION=$(shell git rev-parse --short=7 HEAD)

IMAGE_URI=$(IMAGE_REGISTRY)/$(IMAGE_REPOSITORY)/$(IMAGE_NAME)
IMAGE_URI_VERSION=$(IMAGE_URI):$(IMAGE_VERSION)
IMAGE_URI_LATEST=$(IMAGE_URI):latest
SHELL_CHECK_IMAGE="registry.access.redhat.com/ubi7/ubi:latest"

CONTAINER_ENGINE=$(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null)

default: build

.PHONY: isclean
isclean:
	@(test "$(ALLOW_DIRTY_CHECKOUT)" != "false" || test 0 -eq $$(git status --porcelain | wc -l)) || (echo "Local git checkout is not clean, commit changes and try again." >&2 && exit 1)

.PHONY: build
build: isclean validation shellcheck
	$(CONTAINER_ENGINE) build -t $(IMAGE_URI_VERSION) .
	$(CONTAINER_ENGINE) tag $(IMAGE_URI_VERSION) $(IMAGE_URI_LATEST)

.PHONY: validation
validation:
	./hack/schema_validation.sh

.PHONY: shellcheck
shellcheck:
	$(CONTAINER_ENGINE) pull $(SHELL_CHECK_IMAGE)
	$(CONTAINER_ENGINE) run -v $(shell pwd):/app --entrypoint=/bin/sh -w=/app/scripts $(SHELL_CHECK_IMAGE) -c "yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && yum install -y ShellCheck && find . -name '*.sh' -print0 | xargs -0 -n1 shellcheck -e SC2154 "

.PHONY: push
push:
	$(CONTAINER_ENGINE) push $(IMAGE_URI_VERSION)
	$(CONTAINER_ENGINE) push $(IMAGE_URI_LATEST)

.PHONY: skopeo-push
skopeo-push: build
	skopeo copy \
		--dest-creds "${QUAY_USER}:${QUAY_TOKEN}" \
		"docker-daemon:${IMAGE_URI_VERSION}" \
		"docker://${IMAGE_URI_VERSION}"
	skopeo copy \
		--dest-creds "${QUAY_USER}:${QUAY_TOKEN}" \
		"docker-daemon:${IMAGE_URI_LATEST}" \
		"docker://${IMAGE_URI_LATEST}"
