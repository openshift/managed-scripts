#!/bin/bash

PRINT_SILENCE=1
CREATE_SILENCE=0
CLEAR_SILENCE=0
unset duration

function json_escape {
    echo -e "$*\c" | jq -aRs .
}

SILENCE_JSON=

function prompt_for_silence_info {
    local duration_default creator comment_default start end
	
	duration_default=60
	comment_default="Created by the alert script"
	creator=$USERNAME
    
    if [[ -z "$SILENCE_DURATION" ]] ; then
        duration=$duration_default
    else 
        duration=$SILENCE_DURATION
    fi
    
    if [[ -z "$COMMENT" ]] ; then
        comment="$comment_default"
    else
        comment=$COMMENT
    fi

	start=$(date --iso-8601=seconds --universal)
    end=$(date -d "+$duration minutes" --iso-8601=seconds --universal)

    read -r -d '' SILENCE_JSON <<EOJ
{
  "matchers": [
    {
      "name": "severity",
      "value": "(critical|warning)",
      "isRegex": true
    }
  ],
  "startsAt": "$start",
  "endsAt": "$end",
  "createdBy": $(json_escape "$creator" ),
  "comment": $(json_escape "$comment" ) 
}
EOJ
}

ARG_ARRAY=( $SCRIPT_PARAMETERS )

for ARG in "${ARG_ARRAY[@]}" ; do
    if [[ $INIT_COMMENT == 1 ]] ; then
        unset INIT_COMMENT
        if [[ $ARG = \"* ]] ; then
            # We have a multi-word comments
            COMMENT_ONGOING=1
            COMMENT=${ARG:1}
        elif [[ $ARG =~ ^[-][-]* ]] ; then
            # We expect a comment so shouldn't get an option
               echo "Error : expecting a comment, found an option"
            exit 2
        else
            # If not starting with '--', this is a single-word comment (like a OHSS ticket number)
               COMMENT="$ARG"
        fi
    elif [[ $COMMENT_ONGOING == 1 ]] ; then 
        if [[ $ARG = *\" ]] ; then
            COMMENT+=" ${ARG::-1}"
            unset COMMENT_ONGOING
        else
            COMMENT+=" $ARG"
        fi
    elif [ ! -z "$EXPECT_DURATION" ] ; then
        if ! [[ $ARG =~ ^[1-9][0-9]* ]] ; then
            echo "Invalid duration: must be a positive integer. Aborting."
            exit 1
        else
            SILENCE_DURATION=$ARG
            unset EXPECT_DURATION
        fi
    elif [ ! -z "$EXPECT_USERNAME" ] ; then
        if [[ $ARG =~ ^[-][-]* ]] ; then
            echo "Invalid username: must not start with --. Aborting."
            exit 1
        else
            USERNAME=$ARG
            unset EXPECT_USERNAME
        fi
    elif [ "$ARG" == "--create-silence" ] ; then
        CREATE_SILENCE=1
        PRINT_SILENCE=0
    elif [ "$ARG" == "--list-silences" ] ; then
        PRINT_SILENCE=1
    elif [ "$ARG" == "--clear-silences" ] ; then
        CLEAR_SILENCE=1
        PRINT_SILENCE=0
    elif [ "$ARG" == "--silence-duration" ] ; then
        EXPECT_DURATION=1
    elif [ "$ARG" == "--username" ] ; then
        EXPECT_USERNAME=1
    elif [ "$ARG" == "--silence-comment" ] ; then
        INIT_COMMENT=1
        COMMENT=
    else
        echo "Unexpected value : $ARG"
        echo "usage: script.sh [--create-silence --username <username> {--silence-duration <duration>} {--silence-comment <comment>}|--clear-silences|--list-silences]"
        echo "Default: list the existing silences"
        echo "  --clear-silences   : clear all active silences"
        echo "  --list-silence     : list the currently active  (default action)"
        echo "  --create-silence   : create a silence "
        echo "  --silence-duration : duration in min of the silence when creation one. For silence creation only (for --create-silence only ; optional - default is 60)"
        echo "  --username         : name of the user setting the silence (for --create-silence only ; mandatory)"
        echo "  --silence-comment  : comment for the silence (for --create-silence only ; optional)"
        exit 1
    fi
done

if [[ $((INIT_COMMENT+COMMENT_ONGOING)) -gt 0 ]] ; then
	echo "Check condition: |$INIT_COMMENT|$COMMENT_ONGOING|"
    echo "Aborting. Comment format is not valid"
    exit 1
fi 

if [[ $((EXPECT_DURATION)) -gt 0 ]] ; then
    echo "Aborting. --silence-duration expect a numeric value to be provided"
    exit 1
fi 

if [[ $((EXPECT_USERNAME)) -gt 0 ]] ; then
    echo "Aborting. --username expect a username to be provided"
    exit 1
fi 

if [[ $((CREATE_SILENCE+CLEAR_SILENCE)) -eq 2 ]] ; then
    echo "--create-silence and --clear-silences are mutually exclusive"
    exit 1
fi

function _get_host {
    oc -n openshift-monitoring get routes "$1" -o json | jq -r .spec.host
}

PROM_TOKEN=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
AM_HOST=$(_get_host alertmanager-main)

if [[ $CREATE_SILENCE == 1 ]] ; then
    if [[ -z $USERNAME ]] ; then
        echo "Aborting. Username needs to be provided when setting a silence"
        exit 1
    fi 

    prompt_for_silence_info
    curl -s -k -X POST -H "Content-Type: application/json" --data "$SILENCE_JSON" -H "Authorization: Bearer $PROM_TOKEN" "https://$AM_HOST/api/v1/silences"
fi

if [ $CLEAR_SILENCE == 1 ] ; then
    ALL_SILENCES=$(curl -s -k -H "Authorization: Bearer $PROM_TOKEN"  "https://$AM_HOST/api/v1/silences" | jq -r '.data[] | select(.status.state == "active")')
    if [ ! -z "$ALL_SILENCES" ] ; then
        for SILENCE_ID in $(echo "$ALL_SILENCES" | jq -r .id) ; do
            RESPONSE=$(curl -s -k -X DELETE -H "Authorization: Bearer $PROM_TOKEN"  "https://$AM_HOST/api/v1/silence/${SILENCE_ID}")
            if [ $? == 0 ] ; then
                echo "Deleted silence with ID ${SILENCE_ID}"
            else
                echo "Error deleting silence with ID ${SILENCE_ID}: ${RESPONSE}"
            fi
        done
    else
        echo "No silences to delete."
    fi
fi

if [ $PRINT_SILENCE == 1 ] ; then
    ALL_SILENCES=$(curl -s -k -H "Authorization: Bearer $PROM_TOKEN"  "https://$AM_HOST/api/v1/silences" | jq -r '.data[] | select(.status.state == "active")')
    echo "Silences:"
    if [ -z "$ALL_SILENCES" ] ; then
        echo " - None"
    else
        echo "$ALL_SILENCES" | jq -r .
    fi
fi

