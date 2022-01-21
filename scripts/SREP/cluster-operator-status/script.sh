#!/bin/bash
# This script provides a rich summary of information concerning the status of 
# degraded/unavailable OpenShift cluster operators.
#
# The script can specifically target a cluster operator through
# the use of a "CLUSTER_OPERATOR" parameter
#
# The script can adjust the time interval of logging retrieved through the
# use of the OC_LOGS_SINCE parameter. This parameter can define
# additional options supplied to 'oc logs' when gathering pod logs.
#
# The script can also filter what logging is retrieved through the
# use of the LOG_PATTERN parameter. This parameter defines an 
# extended regular expression passed to grep to filter logs
# after being returned from 'oc logs'
#
set -e
set -o nounset
set -o pipefail


# print_header prints a formatted section break header
print_header() {
    clusteroperator=$1
    heading=$2
    echo -e "--- [ CLUSTER OPERATOR '${clusteroperator}' ${heading} ] ---\n"
}

# get_summary prints the basic status for the given cluster operator parameter
get_summary() {
    clusteroperator=$1

    # shellcheck disable=SC2016
    available=$(jq -r --arg CLUSTER_OPERATOR "${clusteroperator}" '.items[] | select(.metadata.name == $CLUSTER_OPERATOR) | .status.conditions[] | select(.type == "Available") | "\(.status) --> \(.message)"' <<< "$OPERATOR_REPORT")
    # shellcheck disable=SC2016
    progressing=$(jq -r --arg CLUSTER_OPERATOR "${clusteroperator}" '.items[] | select(.metadata.name == $CLUSTER_OPERATOR) | .status.conditions[] | select(.type == "Progressing") | "\(.status) --> \(.message)"' <<< "$OPERATOR_REPORT")
    # shellcheck disable=SC2016
    degraded=$(jq -r --arg CLUSTER_OPERATOR "${clusteroperator}" '.items[] | select(.metadata.name == $CLUSTER_OPERATOR) | .status.conditions[] | select(.type == "Degraded") | "\(.status) --> \(.message)"' <<< "$OPERATOR_REPORT")

    print_header "${clusteroperator}" "SUMMARY"
    echo " - AVAILABLE:   ${available}"
    echo " - DEGRADED:    ${degraded}"
    echo " - PROGRESSING: ${progressing}"
    echo -e "\n"
}

# get_description prints a detailed status description for the given cluster 
# operator parameter
get_description() {
    clusteroperator=$1

    if ! co_desc_report=$(oc describe clusteroperator "${clusteroperator}"); then
       echo "An error was returned when describing ClusterOperator '${clusteroperator}': ${co_desc_report}"
       return
    fi
    print_header "${clusteroperator}" "DESCRIPTION"
    echo -e "${co_desc_report}\n\n"
}

# get_logs prints the last 15 lines of logs from the cluster operator pod
get_logs() {
    clusteroperator=$1
    # Look up all namespaces referenced in status
    # shellcheck disable=SC2016
    relatedns=$(jq -r --arg CLUSTER_OPERATOR "${clusteroperator}" '.items[] | select(.metadata.name == $CLUSTER_OPERATOR) | .status.relatedObjects[] | select(.resource == "namespaces") | .name' <<< "$OPERATOR_REPORT")
    while IFS= read -r ns; do
        ns_report=$(oc get deployment --ignore-not-found -n "$ns" -o name)
        while IFS= read -r deployment; do
            # Look for any deployment which matches an operator deployment.
            # The cluster operator name may or may not have the word operator in it.
            # The cluster operator namespaces may or may not unrelated operator pods in them.
            if [[ "${deployment}" =~ ${clusteroperator} && "${deployment}${clusteroperator}" =~ operator ]]; then
                # deploymentlogs=$(log_cmd "${deployment}" "${ns}")
                if [[ -n "${LOG_PATTERN}" ]]; then
                    # shellcheck disable=SC2046
                    deploymentlogs=$(grep -iE "${LOG_PATTERN}" <<< $(oc logs "${deployment}" -n "${ns}" --all-containers "${OC_LOGS_SINCE}") || true)
                else 
                    deploymentlogs=$(oc logs "${deployment}" -n "${ns}" --all-containers "${OC_LOGS_SINCE}")
                fi
                print_header "${clusteroperator}" "DEPLOYMENT LOGS: ${deployment}"
                echo -e "${deploymentlogs}\n\n"
            fi
        done <<< "${ns_report}"
    done <<< "${relatedns}"
}

# inspect_namespace prints the status of pods running in each namespace 
# that the cluster operator is concerned with
inspect_namespace() {
    clusteroperator=$1

    # Look up all namespaces referenced in status
    # shellcheck disable=SC2016
    relatedns=$(jq -r --arg CLUSTER_OPERATOR "${clusteroperator}" '.items[] | select(.metadata.name == $CLUSTER_OPERATOR) | .status.relatedObjects[] | select(.resource == "namespaces") | .name' <<< "$OPERATOR_REPORT")
    while IFS= read -r ns; do
        ns_report=$(oc get pod --ignore-not-found -n "$ns")
        if [[ -n "${ns_report}" ]]; then
            print_header "$clusteroperator" "NAMESPACE: ${ns}"
            echo -e "${ns_report}\n\n"
        fi
    done <<< "${relatedns}"
}

# Set defaults for retrieving and filtering logs
OC_LOGS_SINCE="${OC_LOGS_SINCE:-}"
if [[ -n "${OC_LOGS_SINCE}" ]]; then
    OC_LOGS_SINCE="--since=${OC_LOGS_SINCE}"
else
    OC_LOGS_SINCE="--tail=15"
fi
LOG_PATTERN="${LOG_PATTERN:-}"

# Retrieve the full ClusterOperator status report
if ! OPERATOR_REPORT=$(oc get clusteroperator -o json); then 
    echo "An error was returned when reading ClusterOperator status: ${OPERATOR_REPORT}"
    exit 1
fi
if [[ -z "${OPERATOR_REPORT}" ]]; then
    echo "No ClusterOperator status was returned."
    exit 1
fi

# Get list of degraded or unavailable operators
CLUSTER_OPERATOR="${CLUSTER_OPERATOR:-}"
if [[ -z "${CLUSTER_OPERATOR}" ]]; then
    # shellcheck disable=SC2016
    CLUSTER_OPERATOR=$(jq -r '.items[] | .metadata as $m | .status.conditions[] | select ((.type == "Degraded" or .type == "Unavailable") and (.status == "True")) | $m.name' <<< "$OPERATOR_REPORT")
    echo "No CLUSTER_OPERATOR parameter specified. Will summarize all degraded or unavailable cluster operators:"
    echo -e "${CLUSTER_OPERATOR}\n\n"
fi

while IFS= read -r co; do
    get_summary "${co}"
    get_description "${co}"
    inspect_namespace "${co}"
    get_logs "${co}"
done <<< "${CLUSTER_OPERATOR}"
