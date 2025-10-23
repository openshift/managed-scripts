#!/bin/bash

MAIN_LOG_BASENAME="rhoam-logs"
timestamp=$(date +"%s")
main_log_dir="${MAIN_LOG_BASENAME}-${timestamp}"
mkdir -p "$main_log_dir"
echo "Created main log directory: $main_log_dir"


function create_directory() {
    if [[ -z "$1" ]]; then
        echo "Error: Component directory name is required."
        echo "Usage: create_directory <component directory-name>"
        return 1
    fi

    sub_dir="$main_log_dir/$1"
    mkdir -p "$sub_dir"
    echo "Created directory: $sub_dir"
}


function 3scale_logs(){
  create_directory "3scale"
  cd "$main_log_dir/3scale" || return

  # Gather logs, creates a log file based on the pod name

  # apicast-production
  for value in $(oc get po -n redhat-rhoam-3scale | grep apicast-production | grep Running| awk '{print $1}'); do oc logs "$value" -c apicast-production -n redhat-rhoam-3scale > "$value.log" ; done
  # apicast-production envoy-sidecar
  for value in $(oc get po -n redhat-rhoam-3scale | grep apicast-production | grep Running| awk '{print $1}'); do oc logs "$value" -c envoy-sidecar -n redhat-rhoam-3scale > "$value-envoy.log" ; done
  # apicast-staging
  for value in $(oc get po -n redhat-rhoam-3scale | grep apicast-staging | grep Running| awk '{print $1}'); do oc logs "$value" -c apicast-staging -n redhat-rhoam-3scale > "$value.log" ; done
  # apicast-staging envoy sidecar
  for value in $(oc get po -n redhat-rhoam-3scale | grep apicast-staging | grep Running| awk '{print $1}'); do oc logs "$value" -c envoy-sidecar -n redhat-rhoam-3scale > "$value.log" ; done

  # backend-cron
  for value in $(oc get po -n redhat-rhoam-3scale | grep backend-cron | grep Running| awk '{print $1}'); do oc logs "$value" -c backend-cron -n redhat-rhoam-3scale > "$value.log" ; done
  # backend-listener
  for value in $(oc get po -n redhat-rhoam-3scale | grep backend-listener | grep Running| awk '{print $1}'); do oc logs "$value" -c backend-listener -n redhat-rhoam-3scale > "$value.log" ; done
  # backend-worker
  for value in $(oc get po -n redhat-rhoam-3scale | grep backend-worker | grep Running| awk '{print $1}'); do oc logs "$value" -c backend-worker -n redhat-rhoam-3scale > "$value.log" ; done

  # system-app
  for value in $(oc get po -n redhat-rhoam-3scale | grep system-app | grep Running| awk '{print $1}'); do oc logs "$value" -c system-master -n redhat-rhoam-3scale > "$value-system-master.log" ; done
  for value in $(oc get po -n redhat-rhoam-3scale | grep system-app | grep Running| awk '{print $1}'); do oc logs "$value" -c system-provider -n redhat-rhoam-3scale > "$value-system-provider.log" ; done
  for value in $(oc get po -n redhat-rhoam-3scale | grep system-app | grep Running| awk '{print $1}'); do oc logs "$value" -c system-developer -n redhat-rhoam-3scale > "$value-system-developer.log" ; done
  # system-memcache
  for value in $(oc get po -n redhat-rhoam-3scale | grep system-memcache | grep Running| awk '{print $1}'); do oc logs "$value" -c memcache -n redhat-rhoam-3scale > "$value.log" ; done
  # system-sidekiq
  for value in $(oc get po -n redhat-rhoam-3scale | grep system-sidekiq | grep Running| awk '{print $1}'); do oc logs "$value" -c system-sidekiq -n redhat-rhoam-3scale > "$value.log" ; done
  # system-sphinx
  for value in $(oc get po -n redhat-rhoam-3scale | grep system-sphinx | grep Running| awk '{print $1}'); do oc logs "$value" -c system-sphinx -n redhat-rhoam-3scale > "$value.log" ; done

  # zync
  for value in $(oc get po -n redhat-rhoam-3scale | grep zync | grep Running| awk '{print $1}'); do oc logs "$value" -n redhat-rhoam-3scale > "$value.log" ; done

  # marin3r
  for value in $(oc get po -n redhat-rhoam-3scale | grep marin3r | grep Running| awk '{print $1}'); do oc logs "$value" -n redhat-rhoam-3scale > "$value.log" ; done

  cd ../.. || return
}

function sso_logs(){
  create_directory "keycloak"
  cd "$main_log_dir/keycloak" || return

  for value in $(oc get po -n redhat-rhoam-rhsso | grep keycloak | grep Running| awk '{print $1}'); do oc logs "$value" -c keycloak -n redhat-rhoam-rhsso > "$value-rhsso.log" ; done
  for value in $(oc get po -n redhat-rhoam-user-sso | grep keycloak | grep Running| awk '{print $1}'); do oc logs "$value" -c keycloak -n redhat-rhoam-user-sso > "$value-user-sso.log" ; done

  cd ../.. || return
}


## Operators logs
function collect_logs_single_pod() {
  local logdir="$1"
  local namespace="$2"
  local pod_pattern="$3"

  create_directory "$logdir"
  cd "$main_log_dir/$logdir" || return

  local pod
  pod=$(oc get po -n "$namespace" | grep "$pod_pattern" | grep Running | awk '{print $1}' | head -n 1)
  [ -n "$pod" ] && oc logs "$pod" -n "$namespace" > "$pod.log"

  cd ../.. || return
}

function rhsso-operator_logs(){
  collect_logs_single_pod "rhsso-operator" "redhat-rhoam-rhsso-operator" "rhsso-operator"
}
function user-sso-operator_logs(){
  collect_logs_single_pod "user-sso-operator" "redhat-rhoam-user-sso-operator" "rhsso-operator"
}
function 3scale-operator_logs() {
  collect_logs_single_pod "3scale-operator" "redhat-rhoam-3scale-operator" "threescale-operator-controller-manager"
}
function cloud-resources-operator_logs() {
  collect_logs_single_pod "cloud-resources-operator" "redhat-rhoam-cloud-resources-operator" "cloud-resource-operator"
}
function customer-monitoring-operator_logs(){
  collect_logs_single_pod "customer-monitoring-operator" "redhat-rhoam-customer-monitoring" "grafana-deployment"
}

function marin3r-operator_logs(){
  create_directory "marin3r-operator"
  cd "$main_log_dir/marin3r-operator" || return
  for value in $(oc get po -n redhat-rhoam-marin3r-operator | grep marin3r-controller | grep Running| awk '{print $1}'); do oc logs "$value" -n redhat-rhoam-marin3r-operator > "$value.log" ; done
  cd ../.. || return
}
function rhoam-operator-observability_logs(){
  create_directory "rhoam-operator-observability"
  cd "$main_log_dir/rhoam-operator-observability" || return
  for value in $(oc get po -n redhat-rhoam-operator-observability | grep alertmanager | grep Running| awk '{print $1}'); do oc logs "$value" -n redhat-rhoam-operator-observability > "$value.log" ; done
  for value in $(oc get po -n redhat-rhoam-operator-observability | grep blackbox-exporter | grep Running| awk '{print $1}'); do oc logs "$value" -n redhat-rhoam-operator-observability > "$value.log" ; done
  for value in $(oc get po -n redhat-rhoam-operator-observability | grep prometheus-rhoam | grep Running| awk '{print $1}'); do oc logs "$value" -n redhat-rhoam-operator-observability > "$value.log" ; done
  cd ../.. || return
}
function rhoam-operator_logs(){
  collect_logs_single_pod "rhoam-operator" "redhat-rhoam-operator" "rhmi-operator"
}

function operators_logs(){
  rhsso-operator_logs
  rhsso-operator_logs
  marin3r-operator_logs
  3scale-operator_logs
  cloud-resources-operator_logs
  customer-monitoring-operator_logs
  rhoam-operator-observability_logs
  rhoam-operator_logs
}

function tar_logdir(){
    tar -zcf "$main_log_dir.tar.gz" ./"$main_log_dir"
}

## main flow

3scale_logs
sso_logs
operators_logs
tar_logdir