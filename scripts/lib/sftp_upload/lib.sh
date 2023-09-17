#!/bin/bash
# Description: provide the sftp_upload function for script to call

# Fail fast and be aware of exit codes
set -euo pipefail

# Constants
readonly FTP_HOST="sftp.access.redhat.com"
readonly SFTP_OPTIONS=(-o BatchMode=no -b)
readonly KNOWN_HOST='sftp.access.redhat.com,35.80.245.1 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCFQ3l2YVJ0r4MNzAZmTV2kg7rPi4WPeJNcNubvOVA4WwBV6cRsYFkIqtB1unBzTXoZHd7+adtZTgUrJ2BExImyLUQaLBu3KKo4CgGeiZMo8dfDvE2tIe/GwGtyho57TtwJVVUCljvFBvbz8+D6VunsQ6kNU53t8qCaBQNm61twTkdAHP9IESJbC7wWJqjmhmOMTav1OKQDtLEsSDc4I+s+h41LvUfw1lA7RSl9eR13TK9ySpN/uW5nBq7nUNWW5OBc3UbvpdQpDXvdUDbW0rQ2EEWvLkKubhk+RSeY/lH8peOeHYQ5ARPYfFDpo5KsKDDdKa9DfnK8N8APgtzM0r+l'

## Upload a file to sftp.access.redhat.com using the unauthenticated flow.
## More about the SFTP server:
## https://access.redhat.com/articles/5594481
##
## Usage: sftp_upload <source-filename> <destination-filename>
## Exmaple: sftp_upload ${PWD}/must-gather.tar.gz must-gather.tar.gz
## The <destination-filename> should be a filename not a path.
function sftp_upload() {
    ## Set up known hosts file
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"
    echo "${KNOWN_HOST}" > "${HOME}/.ssh/known_hosts"

    ## Get a one-time upload token
    creds=$(curl --request POST 'https://access.redhat.com/hydra/rest/v2/sftp/token' \
    --header 'Content-Type: application/json' \
    --data-raw '{
    "isAnonymous" : true
    }')
    username=$(jq -r '.username' <<< "${creds}")
    token=$(jq -r '.token' <<< "${creds}")

    ## Upload the file
    sshpass -p "${token}" sftp "${SFTP_OPTIONS[@]}" - "${username}"@"${FTP_HOST}" << EOSSHPASS
        put $1 $2
        bye
EOSSHPASS

    echo "Uploaded file $1 to ${FTP_HOST}, Anonymous username: ${username}, filename: $2"
    echo "For more information about SFTP: https://access.redhat.com/articles/5594481"
    return 0
}
