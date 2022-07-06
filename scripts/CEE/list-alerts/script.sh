#!/bin/bash

# default is retrieved all firing alerts (critical+warning)
IS_CRITICAL=1
IS_WARNING=1
PRINT_SILENCE=0
NAMESPACE_QUERY="namespace=~\"^$|^default$|^openshift-.*|^kube-.*|^redhat-.*\",namespace!~\"^redhat-rhmi-.*\""
ALERTSTATE_QUERY="alertstate=\"firing\","
declare -A hostarray

# Lists Prometheus hosts on the cluster if the --hosts argument is passed
function list_prometheus_hosts(){
	eval "oc get routes --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name | grep prometheus"
	exit 1
}

# Check if the namespaces provided exist
function check_namespace_exists(){

    # Read in the list of namespaces from the command line argument
    read -r -a PROMETHEUS_HOSTS_ARRAY <<< "$NAMESPACES_TO_CHECK"

# If a namespace in the list doesn't exist, remove it
for NAMESPACE in "${PROMETHEUS_HOSTS_ARRAY[@]}" ; do
	if [[ $(oc get project "${NAMESPACE}" --no-headers) == "" ]]; then
		unset "PROMETHEUS_HOSTS_ARRAY[$NAMESPACE]"
	fi
done
}

# Sets the types of alerts to retrieve (warning, critical, firing-only, pending, all-states)
function set_alert_list(){
	# List of alert states
	ALERT_OPTIONS_ARRAY=($SCRIPT_PARAMETERS)

	for ARG in "${ALERT_OPTIONS_ARRAY[@]}" ; do
		if [ "$ARG" == "--warning-only" ] ; then
			IS_CRITICAL=0
			IS_WARNING_ONLY=1
		elif [ "$ARG" == "--critical-only" ] ; then
			IS_WARNING=0
			IS_CRITICAL_ONLY=1
		elif [ "$ARG" == "--pending-only" ] ; then
			ALERTSTATE_QUERY="alertstate=\"pending\","
			IS_PENDING_ONLY=1
		elif [ "$ARG" == "--firing-only" ] ; then
			ALERTSTATE_QUERY="alertstate=\"firing\","
			IS_FIRING_ONLY=1
		elif [ "$ARG" == "--all-states" ] ; then
			ALERTSTATE_QUERY=""
			NAMESPACE_QUERY=""
			IS_ALL_STATES=1
		elif [ "$ARG" == "--list-silences" ] ; then
			PRINT_SILENCE=1
		else
			echo "usage: script.sh [--warning-only|--critical-only] [--firing-only|--pending-only|--all-states]"
			echo "  --warning-only: print warning alerts only"
			echo "  --critical-only: print critical alerts only"
			echo "  --firing-only: print only firing alert state (default)"
			echo "  --pending-only: print only pending alert state"
			echo "  --all-states: print firing and pending alerts"
			echo "  --list-silences: print all active silences"
			exit 1
		fi
	done
}

function _get_host {
	oc -n "$1" get routes "$2" -o json | jq -r .spec.host
}

function list_alerts(){
	if [[ $((IS_FIRING_ONLY+IS_PENDING_ONLY+IS_ALL_STATES)) -gt 1 ]] ; then
		echo "--pending-only, --firing-only and --all are mutually exclusive."
		exit 2
	fi

	if [[ $((IS_WARNING_ONLY+IS_CRITICAL_ONLY)) -gt 1 ]] ; then
		echo "--warning-only and --critical-only are mutually exclusive."
		exit 2
	fi

	if [[ $IS_ALL_STATES == 1 ]] ; then
		echo "Retrieving pending and firing alerts"
	elif [[ $IS_PENDING_ONLY == 1 ]] ; then
		echo "Retrieving only pending alerts"
	else
		#Default is to retrieve only firing alerts
		echo "Retrieving only firing alerts"
	fi

	if [[ $IS_CRITICAL_ONLY -eq 1 ]] ; then
		echo "Retrieving only Critical alerts"
	elif [[ $IS_WARNING_ONLY -eq 1 ]] ; then
		echo "Retrieving only Warning alerts"
	else
		#Default is to retrieve both Critical and Warning alerts
		echo "Retrieving both Critical and Warning alerts"
	fi

    # If the array is not empty, loop through the list and retrieve the Prometheus route from the supplied namespaces
    if (( ${#PROMETHEUS_HOSTS_ARRAY[@]} ))
    then
	    for NAMESPACE in "${PROMETHEUS_HOSTS_ARRAY[@]}" ; do
		    while read -r a b; do declare -A hostarray["$a"]="$b"; done < <(oc get routes -n "${NAMESPACE}" -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name | grep prometheus)
		    done
	    else
		    # If the array is empty, use the default namespace and host (openshift-monitoring prometheus-k8s)
		    hostarray[openshift-monitoring]=prometheus-k8s
    fi

    for host in "${!hostarray[@]}" ; do
	    echo "Retrieving alerts from the ${hostarray[$host]} Prometheus instance in the ${host} namespace:"
	    PROM_HOST=$(_get_host ${host} ${hostarray[$host]})
	    PROM_TOKEN=$(oc -n ${host} sa get-token ${hostarray[$host]})
	    # The alertmanager route name differs for each namespace, so we need to retrieve it dynamically
	    AM_HOST=$(_get_host "${host}" "$(oc get routes -n ${host} -o custom-columns=NAME:.metadata.name | grep alertmanager)")

# Only set these if we need them
if [[ $((IS_CRITICAL+IS_WARNING)) -gt 0 ]] ; then
	ALL_ALERTS=$(curl -G -s -k -H "Authorization: Bearer $PROM_TOKEN" --data-urlencode "query=ALERTS{${ALERTSTATE_QUERY}${NAMESPACE_QUERY}}" "https://$PROM_HOST/api/v1/query")
	COUNT_CRITICAL=$(echo "$ALL_ALERTS" | jq -r '.data.result[].metric | select(.severity == "critical") | .alertname' | wc -l)
	COUNT_WARNING=$(echo "$ALL_ALERTS" | jq -r '.data.result[].metric | select(.severity == "warning") | select(.alertname != "UsingDeprecatedAPIExtensionsV1Beta1") | select(.alertname != "UsingDeprecatedAPIAppsV1Beta2") | select(.alertname != "UsingDeprecatedAPIAppsV1Beta1") | .alertname' | wc -l)
fi

if [ $IS_CRITICAL == 1 ] ; then
	echo "Critical Alerts:"
	if [ "$COUNT_CRITICAL" = "0" ] ; then
		echo "{}"
	else
		echo "$ALL_ALERTS" | jq -r '.data.result[].metric | select(.severity == "critical") | {alertname, job, namespace, exported_namespace, pod, service, alertstate}'
	fi
fi

if [ $IS_WARNING == 1 ] ; then
	echo "Warning Alerts:"
	if [ "$COUNT_WARNING" = "0" ] ; then
		echo "{}"
	else
		echo "$ALL_ALERTS" | jq -r '.data.result[].metric | select(.severity == "warning") | select(.alertname != "UsingDeprecatedAPIExtensionsV1Beta1") | select(.alertname != "UsingDeprecatedAPIAppsV1Beta2") | select(.alertname != "UsingDeprecatedAPIAppsV1Beta1") | {alertname, job, namespace, exported_namespace, pod, service, alertstate}'
	fi
fi

# Only set this if we need it
if [ $PRINT_SILENCE == 1 ] ; then
	ALL_SILENCES=$(curl -s -k -H "Authorization: Bearer $PROM_TOKEN"  "https://$AM_HOST/api/v1/silences" | jq -r '.data[] | select(.status.state == "active")')
	echo "Silences:"
	if [ -z "$ALL_SILENCES" ] ; then
		echo " - None"
	else
		echo "$ALL_SILENCES" | jq -r .
	fi
fi
done
}

# Check if the --hosts parameter was provided
[[ ${1} == "--hosts" ]] && list_prometheus_hosts

check_namespace_exists
set_alert_list
list_alerts
