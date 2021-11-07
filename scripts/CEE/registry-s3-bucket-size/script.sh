#!/bin/bash

# Compute the size of the bucket backing the in-cluster container registry
# Only AWS clusters with S3 buckets backing the registry are supported

set -e

get_s3_bucket_name() {
  echo "$(oc get configs.imageregistry.operator.openshift.io/cluster -ojsonpath='{.spec.storage.s3.bucket}')"
}

get_s3_access_accesskey() {
  local b64enckey=
  b64enckey=$(oc -n openshift-image-registry get secret image-registry-private-configuration -o jsonpath='{.data.credentials}')
  echo "${b64enckey}" | base64 --decode |  grep aws_access_key_id | cut -d= -f2- | tr -d "[:blank:]"
}

get_s3_access_secretkey() {
  local b64enckey=
  b64enckey=$(oc -n openshift-image-registry get secret image-registry-private-configuration -o jsonpath='{.data.credentials}')
  echo "${b64enckey}" | base64 --decode |  grep aws_secret_access_key | cut -d= -f2- | tr -d "[:blank:]"
}

bucket_size() {
  local bucket="${1}" accesskey="${2}" secretkey="${3}"
  AWS_ACCESS_KEY_ID="${accesskey}" AWS_SECRET_ACCESS_KEY="${secretkey}" aws s3api list-objects --bucket "${bucket}" --output json --query "sum(Contents[].Size)"
}

get_cluster_url() {
  echo "$(oc status | head -n1 | awk '{print $6}')"
}

bucket=$(get_s3_bucket_name)
access=$(get_s3_access_accesskey)
secret=$(get_s3_access_secretkey)

bucket_size_bytes=$(bucket_size "${bucket}" "${access}" "${secret}")
bucket_size_gb=$(echo "${bucket_size_bytes}" | awk '{print $1/1024/1024/1024 " GB "}')

echo "${bucket_size_gb} $(get_cluster_url)"
