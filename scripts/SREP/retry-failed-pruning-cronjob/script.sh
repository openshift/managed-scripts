#!/bin/bash
# Delete and recreate jobs that fail in openshift-sre-pruning namespace and producing prunining cron job error.

set -x
set -e
set -o nounset
set -o pipefail

readonly PRUNING_NS=openshift-sre-pruning

BUILDS_PRUNER=()
DEPLOYMENTS_PRUNER=()
FAILED_JOBS=()
BUILDS_PRUNER_FAILED=()
DEPLOYMENTS_PRUNER_FAILED=()

BUILDS_PRUNER+=($(oc get jobs -n "$PRUNING_NS" -o=jsonpath='{.items[?(@.metadata.ownerReferences[*].name=="builds-pruner")].metadata.name}'))
DEPLOYMENTS_PRUNER+=($(oc get jobs -n "$PRUNING_NS" -o=jsonpath='{.items[?(@.metadata.ownerReferences[*].name=="deployments-pruner")].metadata.name}'))

detect_job() {
  echo "INFO: finding jobs producing error"
  FAILED_JOBS+=($(oc get jobs -n "$PRUNING_NS" -o=jsonpath='{.items[?(@.status.failed>1)].metadata.name}'))
}

delete_job() {
  if [[ ${#FAILED_JOBS[*]} == 0 ]]; then
    echo "INFO: no failed jobs found exiting.."
    return 1
  else
    echo "INFO: deleting jobs producing error"
    for jobs in "${FAILED_JOBS[@]}"; do
      oc delete job "$jobs" -n "$PRUNING_NS"
    done
  fi
}

rerun_job() {
  for jobs in "${FAILED_JOBS[@]}"; do
    if [[ ${BUILDS_PRUNER[@]} =~ ${jobs} ]]; then
      BUILDS_PRUNER_FAILED+=("${jobs}")
    elif [[ ${DEPLOYMENTS_PRUNER[@]} =~ ${jobs} ]]; then
      DEPLOYMENTS_PRUNER_FAILED+=("${jobs}")
    fi  
  done

  if [[ ${#BUILDS_PRUNER_FAILED[*]} != 0 ]]; then
    echo "INFO: creating a builds puner job"
    oc create job --from=cronjob/builds-pruner "${BUILDS_PRUNER_FAILED[0]}" -n "$PRUNING_NS"
  fi

  if [[ ${#DEPLOYMENTS_PRUNER_FAILED[*]} != 0 ]]; then
    echo "INFO: creating a deployments puner job"
    oc create job --from=cronjob/deployments-pruner "${DEPLOYMENTS_PRUNER_FAILED[0]}" -n "$PRUNING_NS"
  fi
}

main() {
  detect_job
  delete_job
  rerun_job
  echo "Succeed."
  exit 0
}

main "$@"