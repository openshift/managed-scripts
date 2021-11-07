#!/bin/bash

set -eEuo pipefail

ERR_NO_DS=1
ERR_UNSUPPORTED=2
ERR_INCORRECT_FLAG=3
# related to error - waitForDaemonsetRollout: Daemonset machine-config-daemon is not ready. status: (desired: 13, updated: 13, ready: 12, unavailable: 1)

DS=${DS:-} # daemonset to run operations on
NS=${NS:-} # namespace the daemonset is in
DELETE=${DELETE:-f} # should we actually delete or verify the command has run sucessfully

ds_labels=$(oc get ds machine-config-daemon -ojsonpath='{.spec.selector.matchLabels}') 
ds_labels_amount=$(echo "${ds_labels}" | jq length)
if [[ "${ds_labels_amount}" -eq 0 ]]; then
  echo "daemonset or namespace incorrect, daemonset labels not found"
  exit "${ERR_NO_DS}"
elif [[ "${ds_labels_amount}" -gt 1 ]]; then
  echo "too many labels, the script currently doesn't support more than one label on the daemonset"
  exit "${ERR_UNSUPPORTED}"
fi
ds_label=$(echo "${ds_labels}"| jq 'to_entries | .[0] |"\(.key)=\(.value)"' -r)

nodenames=$(oc get node -ojsonpath='{.items[*].metadata.name}')

to_remove=()
for ds_nodename in $(oc get po -n ${NS} -l ${ds_label} -ojsonpath='{.items[*].spec.nodeName}'); do 
  if [[ "${IFS}${nodenames[*]}${IFS}" =~ "${IFS}${ds_nodename}${IFS}" ]]; then
    nodenames=( "${nodenames[@]/$ds_nodename}" )
  else
    to_remove+=( ${ds_nodename} )
  fi
done

if [[ "${DELETE}" == "f" ]]; then
  echo "was going to delete the pod.s on node ${to_remove[@]}"
  exit
fi

if [[ "${DELETE}" != "t" ]]; then
  echo "incorrect command for DELETE, please set to 't' for it to work"
  exit "${ERR_INCORRECT_FLAG}"
fi

for node in "${to_remove}"; do
  JSONPATH='{.items[?(@.spec.nodeName == "'${node}'")].metadata.name }'
  pods_on_node=$(oc get po -n ${NS} -l ${ds_label} -ojsonpath="${JSONPATH}")
  first_pod="${pods_on_node[0]}"
  oc delete -n "${NS}" po "${first_pod}"
done
