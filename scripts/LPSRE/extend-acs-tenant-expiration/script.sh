#!/bin/bash

set -e
set -o nounset
set -o pipefail

MISSING_ARG_ERR_CODE=2

usage() {
    cat <<EOF >&2
Usage: ocm backplane managedjob create LPSRE/increase-acs-tenant-expiration -p RHOAS_TOKEN=<RHOAS_TOKEN> -p TENANT_ID=<TENANT_ID> -p MONTHS=<MONTHS> -p REASON=<REASON>
EOF
}

if [[ -z "${RHOAS_TOKEN}" ]]; then
    echo "RHOAS token is not set, get token using 'rhoas authtoken' command and pass using -p RHOAS_TOKEN=<RHOAS_TOKEN>"
    usage
    exit "${MISSING_ARG_ERR_CODE}"
fi

if [[ -z "${TENANT_ID}" ]]; then
    echo "Tenant id is not set, pass using -p TENANT_ID=<TENANT_ID>"
    usage
    exit "${MISSING_ARG_ERR_CODE}"
fi

if [[ -z "${REASON}" ]]; then
    echo "Reason is not set, pass using -p REASON=<REASON>"
    usage
    exit "${MISSING_ARG_ERR_CODE}"
fi

if [[ -z "${MONTHS}" ]]; then
    echo "Defaulting timestamp to 6 months"
    TIMESTAMP=$(date --iso-8601=seconds --utc -d "+6 months")
elif
    TIMESTAMP=$(date --iso-8601=seconds --utc -d "+${MONTHS} months")
fi

update_tenant() {
    curl -H "Authorization: Bearer ${RHOAS_TOKEN}" \
        "https://api.openshift.com/api/rhacs/v1/admin/centrals/${TENANT_ID}/expired-at" \
        -X PATCH \
        --data-urlencode "timestamp=${TIMESTAMP}" --data-urlencode "reason=${REASON}"
}


main(){
    update_tenant
    exit 0
}

main "$@"
