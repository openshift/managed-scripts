#!/bin/bash
# This script checks if any tech preview features are enabled through feature sets.

set -e

# Set of default enabled feature gates; common for OSD clusters.
DEFAULT_FEATURE_GATES=(
"APIPriorityAndFairness=true"
"RotateKubeletServerCertificate=true"
"SupportPodPidsLimit=true"
"NodeDisruptionExclusion=true"
"ServiceNodeExclusion=true"
"DownwardAPIHugePages=true"
"LegacyNodeRoleBehavior=false"
)

getFeatureSet() {
    oc get featuregate cluster -o jsonpath='{.spec.featureSet}'
}

getFeatureGates() {
    oc get kubeapiserver cluster -o json | jq -c '.spec.observedConfig.apiServerArguments["feature-gates"]' | tr '[]",' ' '
}

getAdditionalFeatureGates() {
arg=(${1})
for i in "${arg[@]}"
	do
		if [[ ! ${DEFAULT_FEATURE_GATES[*]}  =~ ${i} ]]; then
			echo "${i}"
		fi
	done
}

feature_set=$(getFeatureSet)

if [ -z "${feature_set}" ]; then
	echo "-> No feature sets enabled."
else
	echo -e "-> '${feature_set}' feature set enabled."
	echo "-> Additional feature gates enabled:"
    feature_gates=$(getFeatureGates)
    getAdditionalFeatureGates "${feature_gates}" 
fi
