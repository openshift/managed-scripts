#!/bin/bash

usage() {
    echo "Usage: $0 IMAGE_URI" >&2
    exit 1
}

## image_exists_in_repo IMAGE_URI
#
# Checks whether IMAGE_URI -- e.g. quay.io/app-sre/osd-metrics-exporter:abcd123
# -- exists in the remote repository.
# If so, returns success.
# If the image does not exist, but the query was otherwise successful, returns
# failure.
# If the query fails for any reason, prints an error and *exits* nonzero.
#
# This function cribbed from:
# https://github.com/openshift/boilerplate/blob/0ba6566d544d0df9993a92b2286c131eb61f3e88/boilerplate/_lib/common.sh#L77-L135
image_exists_in_repo() {
    local image_uri=$1
    local output
    local rc

    local skopeo_stderr=$(mktemp)

    output=$(skopeo inspect docker://${image_uri} 2>$skopeo_stderr)
    rc=$?
    # So we can delete the temp file right away...
    stderr=$(cat $skopeo_stderr)
    rm -f $skopeo_stderr
    if [[ $rc -eq 0 ]]; then
        # The image exists. Sanity check the output.
        local digest=$(echo $output | jq -r .Digest)
        if [[ -z "$digest" ]]; then
            echo "Unexpected error: skopeo inspect succeeded, but output contained no .Digest"
            echo "Here's the output:"
            echo "$output"
            echo "...and stderr:"
            echo "$stderr"
            exit 1
        fi
        echo "Image ${image_uri} exists with digest $digest."
        return 0
    elif [[ "$stderr" == *"manifest unknown"* ]]; then
        # We were able to talk to the repository, but the tag doesn't exist.
        # This is the normal "green field" case.
        echo "Image ${image_uri} does not exist in the repository."
        return 1
    elif [[ "$stderr" == *"was deleted or has expired"* ]]; then
        # This should be rare, but accounts for cases where we had to
        # manually delete an image.
        echo "Image ${image_uri} was deleted from the repository."
        echo "Proceeding as if it never existed."
        return 1
    else
        # Any other error. For example:
        #   - "unauthorized: access to the requested resource is not
        #     authorized". This happens not just on auth errors, but if we
        #     reference a repository that doesn't exist.
        #   - "no such host".
        #   - Network or other infrastructure failures.
        # In all these cases, we want to bail, because we don't know whether
        # the image exists (and we'd likely fail to push it anyway).
        echo "Error querying the repository for ${image_uri}:"
        echo "stdout: $output"
        echo "stderr: $stderr"
        exit 1
    fi
}

set -exv

IMAGE_URI=$1
[[ -z "$IMAGE_URI" ]] && usage


if image_exists_in_repo "$IMAGE_URI"; then
    echo "Image ${IMAGE_URI} already exists. Nothing to do!"
    exit 0
fi

make IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-app-sre} build skopeo-push
