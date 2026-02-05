#!/bin/bash

set -e
set -o nounset
set -o pipefail

ERR_INVALID_NS=2
DELETE=false
FORCE=${FORCE:-}

if [[ -n "${FORCE}" ]]; then
	DELETE=true
fi

if [[ "${NAMESPACE}" != openshift-* && "${NAMESPACE}" != redhat-* ]]; then
	echo "using an invalid namespace, exiting early"
	exit "${ERR_INVALID_NS}"
fi

if ! $DELETE; then
	echo "========================================"
	echo "       DRY-RUN MODE - NO CHANGES        "
	echo "========================================"
	echo "This script is running in DRY-RUN mode."
	echo "NO resources will be deleted."
	echo ""
	echo "To execute deletions, re-run with:"
	echo "  --params NAMESPACE=${NAMESPACE} \\"
	echo "  --params FORCE=y"
	echo "========================================"
	echo ""
fi

SUBSCRIPTION_SAVED=$(oc get subscriptions.operators.coreos.com -n "${NAMESPACE}" -ojson | jq -r 'del(.items[].metadata.annotations."kubectl.kubernetes.io/last-applied-configuration")')
SUBSCRIPTION=$(oc get subscriptions.operators.coreos.com -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}')
CATALOG_SOURCE_SAVED=$(oc get catalogsources.operators.coreos.com -n "${NAMESPACE}" -ojson | jq -r 'del(.items[].metadata.annotations."kubectl.kubernetes.io/last-applied-configuration")')
CATALOG_SOURCE=$(oc get catalogsources.operators.coreos.com -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}')
OPERATOR_GROUP_SAVED=$(oc get operatorgroups.operators.coreos.com -n "${NAMESPACE}" -ojson | jq -r 'del(.items[].metadata.annotations."kubectl.kubernetes.io/last-applied-configuration")')
OPERATOR_GROUP=$(oc get operatorgroups.operators.coreos.com -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}')


if $DELETE; then
  if [[ -n "${SUBSCRIPTION}" ]]; then
    echo "Deleting Subscription: ${SUBSCRIPTION}"
    oc delete subscriptions.operators.coreos.com "${SUBSCRIPTION}" -n "${NAMESPACE}"
  fi
  if [[ -n "${CATALOG_SOURCE}" ]]; then
    echo "Deleting CatalogSource: ${CATALOG_SOURCE}"
    oc delete catalogsources.operators.coreos.com "${CATALOG_SOURCE}" -n "${NAMESPACE}"
  fi
  if [[ -n "${OPERATOR_GROUP}" ]]; then
    echo "Deleting OperatorGroup: ${OPERATOR_GROUP}"
    oc delete operatorgroups.operators.coreos.com "${OPERATOR_GROUP}" -n "${NAMESPACE}"
  fi
else
  echo "[DRY-RUN] Would delete Subscription: ${SUBSCRIPTION}"
  echo "[DRY-RUN] Would delete CatalogSource: ${CATALOG_SOURCE}"
  echo "[DRY-RUN] Would delete OperatorGroup: ${OPERATOR_GROUP}"
fi

"${DELETE}" || echo "[DRY-RUN] Would delete the following CSVs:"
for csv in $(oc get clusterserviceversions.operators.coreos.com -n "${NAMESPACE}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
do
  if "${DELETE}"; then
    echo "Deleting CSV: ${csv}"
    oc delete clusterserviceversions.operators.coreos.com "${csv}" -n "${NAMESPACE}"
  else
    echo -e "\t${csv}"
  fi
done


if "${DELETE}"; then
  if [[ -n "${SUBSCRIPTION}" ]]; then
    echo "Recreating Subscription: ${SUBSCRIPTION}"
    echo "${SUBSCRIPTION_SAVED}" |  oc create -f -
  fi
  if [[ -n "${CATALOG_SOURCE}" ]]; then
    echo "Recreating CatalogSource: ${CATALOG_SOURCE}"
    echo "${CATALOG_SOURCE_SAVED}" | oc create -f -
  fi
  if [[ -n "${OPERATOR_GROUP}" ]]; then
    echo "Recreating OperatorGroup: ${OPERATOR_GROUP}"
    echo "${OPERATOR_GROUP_SAVED}" | oc create -f -
  fi
fi

echo ""
if $DELETE; then
	echo "========================================"
	echo "    DELETION COMPLETED SUCCESSFULLY     "
	echo "========================================"
	echo "All OLM resources have been deleted and recreated."
	echo "========================================"
else
	echo "========================================"
	echo "       DRY-RUN COMPLETED                "
	echo "========================================"
	echo "No resources were deleted."
	echo ""
	echo "To execute these deletions, re-run with:"
	echo "  --params NAMESPACE=${NAMESPACE} \\"
	echo "  --params FORCE=y"
	echo "========================================"
fi
