#!/bin/bash

# Prints the content of haproxy.config from a router to standard output.
# If a pod name is passed as argument, the contents of that pod's configuration
# file is printed; if no router pod is passed, the first default router in
# openshift-ingress is used.

INGRESS_NS="openshift-ingress"
OC_PARAMS="--namespace=${INGRESS_NS} \
	   --output=custom-columns=:.metadata.name\
	   --no-headers"
OC_CMD="oc get pods ${OC_PARAMS}"
SELECTOR="ingresscontroller.operator.openshift.io/deployment-ingresscontroller"
CFG_PATH="/var/lib/haproxy/conf/haproxy.config"

if [ -n "${ROUTER}" ]; then
	POD="$(${OC_CMD} "${ROUTER}")" || exit
else
	POD="$(${OC_CMD} \
		--selector=${SELECTOR}=default \
		--field-selector=status.phase==Running | \
		head --lines=1)"
fi

if [ -z "${POD}" ]; then
	echo "No running router found. Exiting."
	exit 1
fi

echo -e "haproxy.config from ${POD}:\n\n"

oc -n "${INGRESS_NS}" exec "${POD}" -- cat "${CFG_PATH}"
