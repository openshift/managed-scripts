#!/bin/bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

readonly NAMESPACE=openshift-image-registry

# Setting FAILED to true anywhere in this script will print a failure message on exit
FAILED=false

# These traps will still run if "set -o errexit" and "set-o errtrace" are set and an error occurs
trap _cleanup EXIT
trap FAILED=true ERR

# _echo_to_stderr passes all arguments to stderr 
_echo_to_stderr() {
    printf "%s\n" "$*" >&2;
}

# _cleanup is called on exit (even errors) to clean up any changes made to the cluster
_cleanup() {
    # Unset errexit, to avoid stopping cleanup operations on an error
    # Just log the error and continue so it can be manually addressed
    set +o errexit
    
    echo "Cleaning up..."
    local readOnly #SC2155
    readOnly=$(oc get configs.imageregistry.operator.openshift.io/cluster --output=jsonpath='{.spec.readOnly}')

    # Check for "not equal to false", in case the readOnly field is not set or retrieval failed
    if [[ "${readOnly}" != "false" ]]
    then
        # Mark the image registry read-write again
        echo "Marking the image registry read-write again..."
        if ! oc patch configs.imageregistry.operator.openshift.io/cluster --patch='{"spec":{"readOnly":false}}' --type=merge
        then
            # Double-check if the registry is still read-only
                _echo_to_stderr "WARNING: Failed to mark the image registry read-write again."
                _echo_to_stderr "Try: \"oc patch configs.imageregistry.operator.openshift.io/cluster --patch='{\"spec\":{\"readOnly\":false}}' --type=merge\""
        fi
    fi
    
    # No need to run if the service account was never set or retrieved properly
    if [[ -n "${SERVICE_ACCOUNT}" ]]
    then
        # Remove the image-pruner role from the service account
        echo "Removing the image-pruner role from the service account..."
        if ! oc adm policy remove-cluster-role-from-user system:image-pruner -z "${SERVICE_ACCOUNT}" -n "${NAMESPACE}"
        then
            _echo_to_stderr "WARNING: Failed to remove the image-pruner role from the service account."
            _echo_to_stderr "Try: \"oc adm policy remove-cluster-role-from-user system:image-pruner -z ${SERVICE_ACCOUNT} -n ${NAMESPACE}\""
        fi
    fi
    
    # On the off chance that someone in the future uses the cleanup function before the end of the script
    set -o errexit

    # If any failures have occured, make it explicit at the end of the script for manual follow up
    if [[ "${FAILED}" != "false" ]]
    then
        _echo_to_stderr "FAILURE: Pruning the image registry has failed.  Please check the output above for more details."
    fi
}

# _delete_orphaned_blobs runs the actual command inside one of the pods from the registry deployment
_delete_orphaned_blobs() {
    local registry_pod # SC2155
    registry_pod=$(oc get -n "${NAMESPACE}" pod -l docker-registry=default -o jsonpath='{.items[0].metadata.name}')
    oc -n "${NAMESPACE}" exec pod/"${registry_pod}" -- /bin/sh -c '/usr/bin/dockerregistry -prune=delete'
}

# _retry 
_retry() {
    local n=1
    local max=3

    while true
    do
      "${@}" && break
      if [[ $n -lt $max ]]
      then
          _echo_to_stderr "Command failed. Attempt $n/$max:"
          ((n++))
      else
          _echo_to_stderr "The command has failed after $n attempts."
          FAILED=true
          break
      fi
    done
}

main() {
    # Get the service asccount for the registry deployment
    echo "Looking up the service account for the image registry deployment..."
    SERVICE_ACCOUNT=$(oc get -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.serviceAccountName}' deploy/image-registry)

    echo "Adding the image-pruner role to the service account..."
    oc adm policy add-cluster-role-to-user system:image-pruner -z "${SERVICE_ACCOUNT}" -n ${NAMESPACE}
    
    # Mark the image registry read-only
    echo "Marking the image registry read-only..."
    oc patch configs.imageregistry.operator.openshift.io/cluster -p '{"spec":{"readOnly":true}}' --type=merge
    
    # Delete the orphaned blobs (delete mode: `--prune=delete`)
    echo "Deleting the orphaned blobs..."
    # _retry is used because sometimes the pods are removed before the command can be completed
    _retry _delete_orphaned_blobs
} 

main

