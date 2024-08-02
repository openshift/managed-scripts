#!/bin/bash
# Delete and recreate jobs that fail in openshift-sre-pruning namespace and produce pruning cron job errors.

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

mapfile -t BUILDS_PRUNER < <(oc get jobs -n "$PRUNING_NS" -o=jsonpath='{.items[?(@.metadata.ownerReferences[*].name=="builds-pruner")].metadata.name}')
mapfile -t DEPLOYMENTS_PRUNER < <(oc get jobs -n "$PRUNING_NS" -o=jsonpath='{.items[?(@.metadata.ownerReferences[*].name=="deployments-pruner")].metadata.name}')

detect_job() {
  echo "INFO: finding jobs producing error"
  mapfile -t FAILED_JOBS < <(oc get jobs -n "$PRUNING_NS" -o json | jq -r '.items[] | select(.status.succeeded != 1) | .metadata.name')
}

delete_job() {
  if [[ ${#FAILED_JOBS[@]} -eq 0 ]]; then
    echo "INFO: no failed jobs found, exiting.."
    exit 0
  else
    echo "INFO: deleting jobs producing error"
    for job in "${FAILED_JOBS[@]}"; do
      oc delete job "$job" -n "$PRUNING_NS"
    done
  fi
}

rerun_job() {
  for job in "${FAILED_JOBS[@]}"; do
    found=false
    for pruner in "${BUILDS_PRUNER[@]}"; do
      if [[ "$pruner" == "$job" ]]; then
        BUILDS_PRUNER_FAILED+=("$job")
        found=true
        break
      fi
    done

    if ! $found; then
      for pruner in "${DEPLOYMENTS_PRUNER[@]}"; do
        if [[ "$pruner" == "$job" ]]; then
          DEPLOYMENTS_PRUNER_FAILED+=("$job")
          break
        fi
      done
    fi
  done

  if [[ ${#BUILDS_PRUNER_FAILED[@]} -ne 0 ]]; then
    echo "INFO: creating a builds pruner job"
    oc create job --from=cronjob/builds-pruner "${BUILDS_PRUNER_FAILED[0]}" -n "$PRUNING_NS"
  fi

  if [[ ${#DEPLOYMENTS_PRUNER_FAILED[@]} -ne 0 ]]; then
    echo "INFO: creating a deployments pruner job"
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
