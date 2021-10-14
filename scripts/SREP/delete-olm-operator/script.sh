#!/bin/bash

set -e
set -o nounset
set -o pipefail

DELETE=false
if [[ -n "${FORCE}" ]]; then
	DELETE=true
fi

"$DELETE" || echo "Not going to delete resources"

SUBSCRIPTION=$(oc get sub -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}')
CATALOG_SOURCE=$(oc get catalogsource -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}')
OPERATOR_GROUP=$(oc get og -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}')


if $DELETE; then
  if [[ -n "${SUBSCRIPTION}" ]]; then
    echo "Deleting Subscription: ${SUBSCRIPTION}"
    oc delete sub "${SUBSCRIPTION}" -n "${NAMESPACE}"
  fi
  if [[ -n "${CATALOG_SOURCE}" ]]; then
    echo "Deleting CatalogSource: ${CATALOG_SOURCE}"
    oc delete catalogsource "${CATALOG_SOURCE}" -n "${NAMESPACE}" 
  fi
  if [[ -n "${OPERATOR_GROUP}" ]]; then
    echo "Deleting OperatorGroup: ${OPERATOR_GROUP}"
    oc delete og ${OPERATOR_GROUP} -n "${NAMESPACE}" 
  fi
else
  echo "Will delete Subscription: ${SUBSCRIPTION}"
  echo "Will delete CatalogSource: ${CATALOG_SOURCE}"
  echo "Will delete OperatorGroup: ${OPERATOR_GROUP}"
fi

$DELETE || echo "Will delete CSVs:"
for csv in $(oc get csv -n "${NAMESPACE}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
do
  if $DELETE; then
    echo "Deleting CSV: ${csv}"
    oc delete csv $csv -n "${NAMESPACE}"
  else
    echo -e "\t${csv}"
  fi
done

