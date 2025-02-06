#!/usr/bin/env bash

DEBUG=0

# define usage
usage() {
  cat <<EOF
usage: validate-pull-secret -d

optional flags:
  -d | -debug        - Enable debug output
EOF
}

function print_debug() {
  if [[ $DEBUG -ne 0 ]]; then
    echo "[DEBUG] $1"
  fi
}

while [ "$1" != "" ]; do
  case $1 in
    -d | --debug )          shift
                            DEBUG=1
                            ;;
    * ) echo "Unexpected parameter $1"
        usage
        exit 1
  esac
  shift
done

# Retrieve UUID
CLUSTER_UUID=$(oc get clusterversion version -o json | jq -r '.spec.clusterID')

# Retrieve ID
CLUSTER_ID=$(ocm list clusters --parameter search="external_id is '${CLUSTER_UUID}'" --columns id --padding 20 --no-headers)

print_debug "Retrieved cluster UUID $CLUSTER_UUID ID $CLUSTER_ID"

# Retrieve user
SUBSCRIPTION_ID=$(ocm get /api/clusters_mgmt/v1/"$CLUSTER_ID" | jq -r '.subscription.id')
USER_ID=$(ocm get /api/accounts_mgmt/v1/subscriptions/"$SUBSCRIPTION_ID" | jq -r '.creator.id')
USERNAME=$(ocm get /api/accounts_mgmt/v1/accounts/"$USER_ID" | jq -r '.username')

print_debug "Retrieved user $USERNAME with ID $USER_ID associated with subscription $SUBSCRIPTION_ID"

# Retrieve pull secrets
OCM_PULL_SECRET=$(ocm post --body=/dev/null --header="Impersonate-User=$USERNAME" /api/accounts_mgmt/v1/access_token)
if [[ -z $OCM_PULL_SECRET ]]; then
  echo "Could retrieve pull secret from OCM."
  exit 2
fi

CLUSTER_PULL_SECRET=$(oc -n openshift-config get secret pull-secret -o json | jq -r '.data.".dockerconfigjson"' | base64 -d)
if [[ -z $CLUSTER_PULL_SECRET ]]; then
  echo "Could retrieve pull secret from cluster."
  exit 2
fi

# Comparison
KEYS=$(echo "$OCM_PULL_SECRET" | jq -r '.auths | keys[]')

DIFFS=0
for KEY in $KEYS; do
  print_debug "Comparing $KEY"

  OCM_VALUE=$(echo "$OCM_PULL_SECRET" | jq -r --arg key "${KEY}" '.auths.[$key]')
  CLUSTER_VALUE=$(echo "$CLUSTER_PULL_SECRET" | jq -r --arg key "${KEY}" '.auths.[$key]')

  if [ "$OCM_VALUE" != "$CLUSTER_VALUE" ]; then
    print_debug "Invalid $KEY secret"
    DIFFS=$((DIFFS+1))
  fi
done

if [ $DIFFS -eq 0 ]; then
  echo "Valid pull secret."
else
  echo "Invalid pull secret."
fi
