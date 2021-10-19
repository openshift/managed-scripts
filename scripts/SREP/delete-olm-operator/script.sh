#!/bin/bash

set -e
set -o nounset
set -o pipefail

ERR_INVALID_NS=2
DELETE=false
if [[ -n "${FORCE}" ]]; then
	DELETE=true
fi

if [[ "${NAMESPACE}" != openshift-* && "${NAMESPACE}" != redhat-* ]]; then
	echo "using an invalid namespace, exiting early"
	exit "${ERR_INVALID_NS}"
fi

"$DELETE" || echo "Not going to delete resources"

SUBSCRIPTION=$(oc get subscriptions.operators.coreos.com -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}')
CATALOG_SOURCE=$(oc get catalogsources.operators.coreos.com -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}')
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
  echo "Will delete Subscription: ${SUBSCRIPTION}"
  echo "Will delete CatalogSource: ${CATALOG_SOURCE}"
  echo "Will delete OperatorGroup: ${OPERATOR_GROUP}"
fi

$DELETE || echo "Will delete CSVs:"
for csv in $(oc get clusterserviceversions.operators.coreos.com -n "${NAMESPACE}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
do
  if $DELETE; then
    echo "Deleting CSV: ${csv}"
    oc delete clusterserviceversions.operators.coreos.com "${csv}" -n "${NAMESPACE}"
  else
    echo -e "\t${csv}"
  fi
done

