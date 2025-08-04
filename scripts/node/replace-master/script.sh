#!/bin/bash
#
# Replace a master machine.
# Input:
#  (Env) MACHINE
#    name of the machine resource in cluster

set -x
set -e
set -o nounset
set -o pipefail

readonly MACHINE_NS=openshift-machine-api
readonly ETCD_NS=openshift-etcd

validate_input() {
  echo "INFO: validating input MACHINE=$MACHINE"
  if [[ -z "$MACHINE" ]]; then
    echo "ERROR: the environment variable MACHINE cannot be blank" >&2
    return 1
  fi

  if ! [[ "$MACHINE" =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo "ERROR: the environment variable MACHINE should only include lower case characters or hyphen" >&2
    return 1
  fi
}

#######################################
# Preflight check:
# - if cluster version is supported by this script
# - if the given machine is master
# - if the other 2 masters are healthy
# - if the other 2 etcd members are healthy
# Globals:
#   MACHINE_NS
#   ETCD_NS
#   MACHINE
# Arguments:
#   None
#######################################
preflight_check() {
  # only support cluster <= 4.10
  echo "INFO: validating if cluster version is supported"
  local version
  version=$(oc version -o json | jq ".openshiftVersion")
  grep -E '4.8|4.9|4.10' <<< "$version" ||
    { echo "ERROR: only support cluster version 4.8, 4.9 and 4.10" >&2; return 1; }

  # fail if an upgrade is running
  echo "INFO: validating if cluster upgrade is on-going"
  local upgrade
  upgrade=$(oc get upgrade -A --ignore-not-found | wc -l)
  if [[ $upgrade -gt 0 ]]; then
    echo "ERROR: an upgrade is running" >&2
    return 1
  fi

  # fail if the machine is not a master
  echo "INFO: validating if $MACHINE is a master"
  local master_machines
  local master_nodes
  local is_master
  master_machines=$(oc get machine -n $MACHINE_NS -l machine.openshift.io/cluster-api-machine-type=master --no-headers -o custom-columns=NAME:.metadata.name,node:.status.nodeRef.name)
  master_nodes=$(oc get node -l node-role.kubernetes.io/master --no-headers)
  is_master=$( { grep "$MACHINE" || true; } <<< "$master_machines" | wc -l)
  if [[ $is_master -ne 1 ]]; then
    echo "ERROR: the machine $MACHINE does not show up in $MACHINE_NS as a master" >&2
    return 1
  fi

  # fail if the other 2 masters are not healthy
  echo "INFO: validating if the other 2 masters are healthy"
  local other_machine_machines
  other_machine_machines=$( { grep -v "$MACHINE" || true; } <<< "$master_machines")
  if [[ $(wc -l <<< "$other_machine_machines") -ne 2 ]]; then
    echo "ERROR: master machines not equal 2 besides $MACHINE" >&2
    return 1
  fi

  local other_master_nodes
  other_master_nodes=$(awk '{print $2}' <<< "$other_machine_machines")
  if [[ $(wc -l <<< "$other_master_nodes") -ne 2 ]]; then
    echo "ERROR: master nodes not equal 2 besides $MACHINE" >&2
    return 1
  fi

  for node in $other_master_nodes; do
    if [[ $( { grep "$node" || true; } <<< "$master_nodes" | { grep -vi "NotReady" || true; } | wc -l) -ne 1 ]]; then
      echo "ERROR: $node not in Ready state" >&2
      return 1
    fi
  done

  # fail if the other 2 etcd members are not healthy
  echo "INFO: validating if the other 2 etcd members are healthy"
  local etcd_pod
  local etcd_members
  etcd_pod=$(oc get pod -n $ETCD_NS  -l etcd=true | grep Running | head -n1 | awk '{print $1}')
  etcd_members=$(oc rsh -n $ETCD_NS -c etcdctl "$etcd_pod" etcdctl member list -w simple)
  for node in $other_master_nodes; do
    if [[ $( { grep "$node" || true; } <<< "$etcd_members" | { grep started || true; } | wc -l) -ne 1 ]]; then
      echo "ERROR: etcd $node not in started state" >&2
      return 1
    fi
  done
}

#######################################
# Delete the old machine and create a
# new machine with the same spec.
# Globals:
#   MACHINE_NS
#   MACHINE
# Arguments:
#   None
#######################################
replace_machine() {
  echo "INFO: replacing the master machine"
  local old_master_json
  local spec
  local api_version
  local labels
  local new_master_json
  old_master_json=$(oc -n "$MACHINE_NS" get machine "$MACHINE" -o json)
  spec=$(jq '.spec' <<< "$old_master_json" | jq '.providerID |= ""')
  api_version=$(jq -r '.apiVersion' <<< "$old_master_json")
  labels=$(jq '.metadata.labels' <<< "$old_master_json")
  # shellcheck disable=SC2016
  new_master_json=$( jq -n \
                    --arg apiVersion "$api_version" \
                    --arg name "$MACHINE" \
                    --argjson labels "$labels" \
                    --arg namespace "$MACHINE_NS" \
                    --argjson spec "$spec" \
                    '{ "apiVersion": $apiVersion, "kind": "Machine", "metadata": { "name": $name, "namespace": $namespace, labels: $labels}, "spec": $spec }' )
  # delete the master machine
  # usually the oc delete command will block until the machine is gone.
  # in some cases when the master node is gone, the oc command will fail
  # to watch the status, so sleep 300s in such case.
  oc delete machine "$MACHINE" -n $MACHINE_NS || sleep 300

  # check if only 2 running masters are left
  echo "INFO: waiting for the original master to be deleted..."
  sleep 600 # wait some time here for etcd election.
  if [[ $(oc get node -l node-role.kubernetes.io/master --no-headers | wc -l) -ne 2 ]]; then
    echo "ERROR: current master nodes are not equal to 2 after deleting $MACHINE" >&2
    return 1
  fi

  echo "INFO: creating the new master"
  oc create -f - <<< "$new_master_json"

  # wait until all 3 masters are running
  echo "INFO: waiting for the new master to become ready..."
  # it takes at most 10 mins for a machine to become ready
  # otherwise machine-api will delete and retry.
  sleep 600
  if [[ $( oc get node -l node-role.kubernetes.io/master --no-headers | { grep -iv "NotReady" || true; } | wc -l) -ne 3 ]]; then
    echo "ERROR: master nodes with the state 'Ready' are not equal to 3" >&2
    return 1
  fi
}

#######################################
# Clean up orphan secrets and orphan
# etcd members, wait until all 3 etcd
# become healthy.
# Globals:
#   ETCD_NS
# Arguments:
#   None
#######################################
post_replace() {
  # delete orphan etcd secrets
  echo "INFO: deleting the orphan secrects"
  local living_masters
  local orphan_secrets
  living_masters=$(oc get node -l node-role.kubernetes.io/master --no-headers -o custom-columns=NAME:.metadata.name)
  orphan_secrets=$(oc get secret -n $ETCD_NS --no-headers -o custom-columns=NAME:.metadata.name | grep -E 'etcd-serving-|etcd-peer-|etcd-serving-metrics-')
  for master in $living_masters; do
    orphan_secrets=$( { grep -v "$master" || true; } <<< "$orphan_secrets")
  done

  for scrt in $orphan_secrets; do
    oc delete secret "$scrt" -n $ETCD_NS
  done

  # redeploy etcd
  oc patch etcd cluster -p='{"spec": {"forceRedeploymentReason": "single-master-recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge

  # delete orphan etcd member
  echo "INFO: deleting the orphan etcd member"
  local etcd_pod
  local etcd_members
  local etcd_mem_to_delete
  etcd_pod=$(oc get pod -n $ETCD_NS  -l etcd=true | grep Running | head -n1 | awk '{print $1}')
  etcd_members=$(oc rsh -n $ETCD_NS -c etcdctl "$etcd_pod" etcdctl member list -w simple)
  etcd_mem_to_delete=$etcd_members
  for master in $living_masters; do
    etcd_mem_to_delete=$({ grep -v "$master" || true; } <<< "$etcd_mem_to_delete")
  done

  if [[ $(wc -l <<< "$etcd_mem_to_delete") -gt 1 ]]; then
    echo "ERROR: there are more than 1 etcd members having no corresponding running masters, further human investigation needed" >&2
    return 1
  fi

  if [[ -n $etcd_mem_to_delete ]]; then
    local etcd_id_to_delete
    etcd_id_to_delete=$(awk -F',' '{print $1}' <<< "$etcd_mem_to_delete")
    oc rsh -n $ETCD_NS -c etcdctl "$etcd_pod" etcdctl member remove "$etcd_id_to_delete"
  fi

  # wait until it succeed
  echo "INFO: wait until all etcd members are healthy"
  local retry=15
  local succeed=0
  local ep_health_info
  while [[ $retry -gt 0 ]]; do
    retry=$((retry-1))
    sleep 60
    ep_health_info=$( { (oc rsh -n $ETCD_NS -c etcdctl "$etcd_pod" etcdctl endpoint health -w fields) || true; })
    if [[ $( { grep "true" || true; } <<< "$ep_health_info" | wc -l ) -eq 3 ]]; then
        succeed=1
        break
    fi
  done

  if [[ $succeed -eq 1 ]]; then
    echo "ETCD has 3 healthy members, master replacement successful!"
    return 0
  else
    echo "ERROR: ETCD doesn't have 3 healthy members, need human investigation." >&2
    return 1
  fi
}

main() {
  validate_input
  preflight_check
  replace_machine
  post_replace
  echo "Succeed."
  exit 0
}

main "$@"
