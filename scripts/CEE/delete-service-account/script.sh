#!/bin/bash

set -e
set -o nounset
set -o pipefail

NAMESPACE=default

CURRENTDATE=$(date +"%Y-%m-%d %T")

if [[ -z "${SERVICE_ACCOUNT}" ]]; then
    echo "Variable SERVICE_ACCOUNT cannot be blank"
    exit 1
fi

start_job(){
    echo "Job started at $CURRENTDATE"
    echo ".................................."
    echo
}

finish_job(){
    echo
    echo ".................................."
    echo "Job finished at $CURRENTDATE"
}


## Get info about existing service accounts
get_existing_sa(){

    echo -e "\nVerifying all existing service accounts in the default namespace\n"
    oc get sa -n default
}

## Delete required service account

delete_sa(){

echo -e "\nChecking if service account \"${SERVICE_ACCOUNT}\" exists in the default namespace\n"

    if (oc get sa -n default -o name | grep "${SERVICE_ACCOUNT}") &> /dev/null; then
        echo -e "[OK] \"${SERVICE_ACCOUNT}\" is present and can be deleted. Proceeding with delition...\n"

        oc delete sa/"${SERVICE_ACCOUNT}" -n default

        echo -e "\nVerifying all remaining service accounts\n"

        oc get sa -n default

    else
        echo "[Error] service account \"${SERVICE_ACCOUNT}\" is not present. Exiting script..."
        exit 1
    fi


}

main(){
    start_job
    get_existing_sa
    delete_sa
    finish_job
}

main
