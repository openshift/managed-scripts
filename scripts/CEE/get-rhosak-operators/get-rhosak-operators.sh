#!/bin/bash

function create_directory(){
    timestamp=$(date +%s)
    directory="inspect.RHOSAK.$timestamp"
    mkdir "$directory"
    sinceFlag=()
        if [[ -v since ]]; then
            sinceFlag+=("--since=$since")
        elif [[ -v since_time ]]; then
            sinceFlag+=("--since-time=$since_time")
        fi
}

function fleetshard(){
    oc adm inspect ns/redhat-kas-fleetshard-operator "${sinceFlag[@]}" --dest-dir "$directory" > "$directory"/rhosak.log 2>&1
}
function observability(){
    oc adm inspect ns/managed-application-services-observability "${sinceFlag[@]}" --dest-dir "$directory" > "$directory"/rhosak.log 2>&1
}
function strimzi(){
    oc adm inspect  ns/redhat-managed-kafka-operator "${sinceFlag[@]}" --dest-dir "$directory" > "$directory"/rhosak.log 2>&1
}
function agent(){
    oc get -o yaml managedkafkaagents -n redhat-kas-fleetshard-operator > "$directory"/managed-kafka-agents.txt 2>&1
}
function clean(){
    find "$directory" -type f -name "rhosak.log" -delete
    find "$directory" -type f -name secrets.yaml -delete
    find "$directory" -name "*.txt" -exec sed -i '/accessToken:/d' {} \;
    tar -zcf  "$directory".tar.gz ./"$directory"
}

create_directory
fleetshard
observability
strimzi
agent
clean