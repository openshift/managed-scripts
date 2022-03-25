#!/bin/bash

# exit on error
set -e

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

hiveconfig=$(oc get hiveconfig hive -o json)
if [ -z "$hiveconfig" ] ; then
  echo "Error: Unable to retrieve hiveconfig."
  exit 10
fi

bucket=$(echo "$hiveconfig" | jq -r '.spec.failedProvisionConfig.aws.bucket')
if [ -z "$bucket" -o "$bucket" == "null" ] ; then
  echo "Error: Unable to determine S3 bucket from hiveconfig."
  exit 10
fi

region=$(echo "$hiveconfig" | jq -r '.spec.failedProvisionConfig.aws.region')
if [ -z "$region" -o "$region" == "null" ] ; then
  echo "Error: Unable to determine AWS region from hiveconfig."
  exit 10
fi

secret_name=$(echo "$hiveconfig" | jq -r '.spec.failedProvisionConfig.aws.credentialsSecretRef.name')
if [ -z "$secret_name" -o "$secret_name" == "null" ] ; then
  echo "Error: Unable to determine AWS credentials secret name from hiveconfig."
  exit 10
fi

credentials_secret=$(oc get secret -n hive -o json "$secret_name")
if [ -z "$credentials_secret" -o "$credentials_secret" == "null" ] ; then
  echo "Error: Unable to retrieve credentials secret [$secret_name]."
  exit 10
fi

AWS_ACCESS_KEY_ID=$(echo "$credentials_secret" | jq -r '.data.aws_access_key_id' | base64 -d)
if [ -z "$AWS_ACCESS_KEY_ID" -o "$AWS_ACCESS_KEY_ID" == "null" ] || [[ "$AWS_ACCESS_KEY_ID" != AKIA* ]] ; then
  echo "Error: Unable to retrieve aws_access_key_id from secret [$secret_name] in the hive namespace."
  exit 10
fi

AWS_SECRET_ACCESS_KEY=$(echo "$credentials_secret" | jq -r '.data.aws_secret_access_key' | base64 -d)
if [ -z "$AWS_SECRET_ACCESS_KEY" -o "$AWS_SECRET_ACCESS_KEY" == "null" ]; then
  echo "Error: Unable to retrieve aws_secret_access_key from secret [$secret_name] in the hive namespace."
  exit 10
fi

echo "Bucket [$bucket] contents:"
aws s3 ls "s3://${bucket}/"
echo