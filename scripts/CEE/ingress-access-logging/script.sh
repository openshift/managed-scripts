#!/bin/bash

# Toggle ingress access logging on OpenShift 4.14+
# Reference: https://docs.openshift.com/container-platform/4.14/networking/ingress-operator.html#nw-configure-ingress-access-logging_configuring-ingress

set -e
set -o nounset
set -o pipefail

INGRESS_NAME="default"
INGRESS_NAMESPACE="openshift-ingress-operator"

check_access_logging_status() {
  echo "Verifying current access logging configuration..."
  oc get ingresscontroller "$INGRESS_NAME" -n "$INGRESS_NAMESPACE" -o json | jq -r '
    if .spec.logging.access.destination.type then
      "Access logging is ENABLED (type: \(.spec.logging.access.destination.type), format: \(.spec.logging.access.httpLogFormat))"
    else
      "Access logging is DISABLED"
    end
  '
}

enable_access_logging() {
  echo "Enabling ingress access logging..."
  oc patch ingresscontroller "$INGRESS_NAME" -n "$INGRESS_NAMESPACE" --type=merge -p '{
    "spec": {
      "logging": {
        "access": {
          "destination": {
            "type": "Container"
          },
        }
      }
    }
  }'
  echo "Access logging enabled."
}

disable_access_logging() {
  echo "Disabling ingress access logging..."
  oc patch ingresscontroller "$INGRESS_NAME" -n "$INGRESS_NAMESPACE" --type=json -p='[
    {"op": "remove", "path": "/spec/logging"}
  ]'
  echo "Access logging disabled."
}

main() {
  if [[ -z "${ACCESS_LOGGING}" || ( "$ACCESS_LOGGING" != "enable" && "$ACCESS_LOGGING" != "disable" ) ]]; then
    echo "Error: ACCESS_LOGGING must be set to 'enable' or 'disable'"
    exit 1
  fi

  if [[ "$ACCESS_LOGGING" == "enable" ]]; then
    enable_access_logging
  else
    disable_access_logging
  fi

  check_access_logging_status
}

main