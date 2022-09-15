#!/bin/bash

set -x
set -e
set -o nounset
set -o pipefail

readonly MACHINE_NS=openshift-machine-api
readonly ETCD_NS=openshift-etcd

validate_input() {
echo "INFO: validating input machine=$machine"
if [[ -z "$machine" ]]
then
    echo "ERROR: variable machine cannot be blank"
    return 1
fi

if ! [[ "$machine" =~ ^[a-zA-Z0-9-]+$ ]]
then
    echo "ERROR: the machine name should only include lower case characters or hyphen"
    return 1
fi

### only support cluster <= 4.10
echo "INFO: validating if cluster version is supported"
VERSION=$(oc version -o json | jq ".openshiftVersion")
grep -E '4.8|4.9|4.10' <<< "$VERSION" || { echo "ERROR: only support cluster version 4.8, 4.9 and 4.10"; return 1; }

### fail if an upgrade is running
echo "INFO: validating if cluster upgrade is on-going"
UPGRADE=$(oc get upgrade -A --ignore-not-found | wc -l)
if [[ $UPGRADE -gt 0 ]]
then
    echo "ERROR: an upgrade is running"
    return 1
fi

### fail if the machine is not a master
echo "INFO: validating if $machine is a master"
MASTER_MACHINES=$(oc get machine -n $MACHINE_NS -l machine.openshift.io/cluster-api-machine-type=master --no-headers -o custom-columns=NAME:.metadata.name,node:.status.nodeRef.name)
MASTER_NODES=$(oc get node -l node-role.kubernetes.io/master --no-headers)
IS_MASTER=$( { grep "$machine" || true; } <<< "$MASTER_MACHINES" | wc -l)
if [[ $IS_MASTER -ne 1 ]]
then
    echo "ERROR: the machine $machine does not show up in $MACHINE_NS as a master"
    return 1
fi

### fail if the other 2 masters are not healthy
echo "INFO: validating if the other 2 masters are healthy"
OTHER_MASTER_MACHINES=$( { grep -v "$machine" || true; } <<< "$MASTER_MACHINES")
if [[ $(wc -l <<< "$OTHER_MASTER_MACHINES") -ne 2 ]]
then
    echo "ERROR: master machines not equal 2 besides $machine"
    return 1
fi
OTHER_MASTER_NODES=$(awk '{print $2}' <<< "$OTHER_MASTER_MACHINES")
if [[ $(wc -l <<< "$OTHER_MASTER_NODES") -ne 2 ]]
then
    echo "ERROR: master nodes not equal 2 besides $machine"
    return 1
fi
for node in $OTHER_MASTER_NODES
do
    if [[ $( { grep "$node" || true; } <<< "$MASTER_NODES" | { grep -vi "NotReady" || true; } | wc -l) -ne 1 ]]
    then
        echo "ERROR: $node not in Ready state"
        return 1
    fi
done

### fail if the other 2 etcd members are not healthy
echo "INFO: validating if the other 2 etcd members are healthy"
ETCD_POD=$(oc get pod -n $ETCD_NS  -l etcd=true | grep Running | head -n1 | awk '{print $1}')
ETCD_MEMBERS=$(oc rsh -n $ETCD_NS -c etcdctl "$ETCD_POD" etcdctl member list -w simple)
for node in $OTHER_MASTER_NODES
do
    if [[ $( { grep "$node" || true; } <<< "$ETCD_MEMBERS" | { grep started || true; } | wc -l) -ne 1 ]]
    then
       echo "ERROR: etcd $node not in started state"
       return 1
    fi
done
}

replace_machine() {
echo "INFO: replacing the master machine"
ORIGN_MASTER_JSON=$(oc -n "$MACHINE_NS" get machine "$machine" -o json)
SPEC=$(jq '.spec' <<< "$ORIGN_MASTER_JSON" | jq '.providerID |= ""')
API_VERSION=$(jq -r '.apiVersion' <<< "$ORIGN_MASTER_JSON")
LABELS=$(jq '.metadata.labels' <<< "$ORIGN_MASTER_JSON")
# shellcheck disable=SC2016
NEW_MASTER_JSON=$( jq -n \
                  --arg apiVersion "$API_VERSION" \
                  --arg name "$machine" \
                  --argjson labels "$LABELS" \
                  --arg namespace "$MACHINE_NS" \
                  --argjson spec "$SPEC" \
                  '{ "apiVersion": $apiVersion, "kind": "Machine", "metadata": { "name": $name, "namespace": $namespace, labels: $labels}, "spec": $spec }' )

### delete the master machine
### usually the oc delete command will block until the machine is gone.
### in some cases when the master node is gone, the oc command will fail to watch the status, so sleep 300s in such case.
oc delete machine "$machine" -n $MACHINE_NS || sleep 300

### check if only 2 running masters are left
echo "INFO: wait for the original master gone"
sleep 600 # wait some time here for etcd election.
if [[ $(oc get node -l node-role.kubernetes.io/master --no-headers | wc -l) -ne 2 ]]
then
    echo "ERROR: The living master nodes not equal 2 after deleting $machine"
    return 1
fi

echo "INFO: creating the new master"
oc create -f - <<< "$NEW_MASTER_JSON"

### wait until all 3 masters are running
echo "INFO: wait for the new master become ready"
sleep 600 # it takes at most 10 mins for a machine to become ready otherwise machine-api will delete and retry.
if [[ $( oc get node -l node-role.kubernetes.io/master --no-headers | { grep -iv "NotReady" || true; } | wc -l) -ne 3 ]]
then
    echo "ERROR: Ready master nodes not equal 3"
    return 1
fi
}

post_replace() {
## delete orphan etcd secrets
echo "INFO: deleting the orphan secrects"
LIVING_MASTERS=$(oc get node -l node-role.kubernetes.io/master --no-headers -o custom-columns=NAME:.metadata.name)
ORPHAN_SECRETS=$(oc get secret -n $ETCD_NS --no-headers -o custom-columns=NAME:.metadata.name | grep -E 'etcd-serving-|etcd-peer-|etcd-serving-metrics-')
for master in $LIVING_MASTERS
do
    ORPHAN_SECRETS=$( { grep -v "$master" || true; } <<< "$ORPHAN_SECRETS")
done

for scrt in $ORPHAN_SECRETS
do
    oc delete secret "$scrt" -n $ETCD_NS
done

oc patch etcd cluster -p='{"spec": {"forceRedeploymentReason": "single-master-recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge

## delete orphan etcd member
echo "INFO: deleting the orphan etcd member"
ETCD_POD=$(oc get pod -n $ETCD_NS  -l etcd=true | grep Running | head -n1 | awk '{print $1}')
ETCD_MEMBERS=$(oc rsh -n $ETCD_NS -c etcdctl "$ETCD_POD" etcdctl member list -w simple)
ETCD_MEM_TO_DELETE=$ETCD_MEMBERS
for master in $LIVING_MASTERS
do
    ETCD_MEM_TO_DELETE=$({ grep -v "$master" || true; } <<< "$ETCD_MEM_TO_DELETE")
done

if [[ $(wc -l <<< "$ETCD_MEM_TO_DELETE") -gt 1 ]]
then
    echo "ERROR: There are more than 1 etcd members have no corresponding running masters, need human investigation"
    return 1
fi

if [[ -n $ETCD_MEM_TO_DELETE ]]
then
    ETCD_ID_TO_DELETE=$(awk -F',' '{print $1}' <<< "$ETCD_MEM_TO_DELETE")
    oc rsh -n $ETCD_NS -c etcdctl "$ETCD_POD" etcdctl member remove "$ETCD_ID_TO_DELETE"
fi

## wait until it succeed
echo "INFO: wait until all etcd members are healthy"
RETRY=15
SUCCEED=0
while [[ $RETRY -gt 0 ]]
do
    RETRY=$((RETRY-1))
    sleep 60
    EP_HEALTH_INFO=$( { (oc rsh -n $ETCD_NS -c etcdctl "$ETCD_POD" etcdctl endpoint health -w fields) || true; })
    if [[ $( { grep "true" || true; } <<< "$EP_HEALTH_INFO" | wc -l ) -eq 3 ]]
    then
        SUCCEED=1
        break
    fi
done

if [[ $SUCCEED -eq 1 ]]
then
    echo "ETCD has 3 healthy members, master replacement succeed"
    return 0
else
    echo "ERROR: ETCD doesn't have 3 healthy members, need human investigation."
    return 1
fi
}

validate_input
replace_machine
post_replace

echo "Succeed."
exit 0
