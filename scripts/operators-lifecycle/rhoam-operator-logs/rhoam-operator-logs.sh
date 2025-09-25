#!/bin/bash

MAIN_LOG_BASENAME="rhoam-logs"
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
main_log_dir="${MAIN_LOG_BASENAME}-${timestamp}"
mkdir -p "$main_log_dir"
echo "Created main log directory: $main_log_dir"

## === Handle 'since' value and create since file if defined ===
#if [[ -n ${since+x} ]]; then
#    since_str=$(date -d "$since" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || echo "$since")
#elif [[ -n ${since_time+x} ]]; then
#    since_str=$(date -d "$since_time" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || echo "$since_time")
#else
#    since_str=""
#fi
#
#if [[ -n "$since_str" ]]; then
#    since_file="$main_log_dir/since_${since_str//[:]/-}.txt"
#    echo "$since_str" > "$since_file"
#    echo "Created since file: $since_file"
#fi

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
  cd "$main_log_dir/3scale"

  # Gather logs, creates a log file based on the pod name

  # apicast-production
  for value in $(oc get po -n redhat-rhoam-3scale | grep apicast-production | grep Running| awk '{print $1}'); do oc logs $value -c apicast-production -n redhat-rhoam-3scale > $value.log ; done
  # apicast-production envoy-sidecar
  for value in $(oc get po -n redhat-rhoam-3scale | grep apicast-production | grep Running| awk '{print $1}'); do oc logs $value -c envoy-sidecar -n redhat-rhoam-3scale > $value-envoy.log ; done
  # apicast-staging
  for value in $(oc get po -n redhat-rhoam-3scale | grep apicast-staging | grep Running| awk '{print $1}'); do oc logs $value -c apicast-staging -n redhat-rhoam-3scale > $value.log ; done
  # apicast-staging envoy sidecar
  for value in $(oc get po -n redhat-rhoam-3scale | grep apicast-staging | grep Running| awk '{print $1}'); do oc logs $value -c envoy-sidecar -n redhat-rhoam-3scale > $value.log ; done

  # backend-cron
  for value in $(oc get po -n redhat-rhoam-3scale | grep backend-cron | grep Running| awk '{print $1}'); do oc logs $value -c backend-cron -n redhat-rhoam-3scale > $value.log ; done
  # backend-listener
  for value in $(oc get po -n redhat-rhoam-3scale | grep backend-listener | grep Running| awk '{print $1}'); do oc logs $value -c backend-listener -n redhat-rhoam-3scale > $value.log ; done
  # backend-worker
  for value in $(oc get po -n redhat-rhoam-3scale | grep backend-worker | grep Running| awk '{print $1}'); do oc logs $value -c backend-worker -n redhat-rhoam-3scale > $value.log ; done

  # system-app
  for value in $(oc get po -n redhat-rhoam-3scale | grep system-app | grep Running| awk '{print $1}'); do oc logs $value -c system-master -n redhat-rhoam-3scale > $value-system-master.log ; done
  for value in $(oc get po -n redhat-rhoam-3scale | grep system-app | grep Running| awk '{print $1}'); do oc logs $value -c system-provider -n redhat-rhoam-3scale > $value-system-provider.log ; done
  for value in $(oc get po -n redhat-rhoam-3scale | grep system-app | grep Running| awk '{print $1}'); do oc logs $value -c system-developer -n redhat-rhoam-3scale > $value-system-developer.log ; done
  # system-memcache
  for value in $(oc get po -n redhat-rhoam-3scale | grep system-memcache | grep Running| awk '{print $1}'); do oc logs $value -c memcache -n redhat-rhoam-3scale > $value.log ; done
  # system-sidekiq
  for value in $(oc get po -n redhat-rhoam-3scale | grep system-sidekiq | grep Running| awk '{print $1}'); do oc logs $value -c system-sidekiq -n redhat-rhoam-3scale > $value.log ; done
  # system-sphinx
  for value in $(oc get po -n redhat-rhoam-3scale | grep system-sphinx | grep Running| awk '{print $1}'); do oc logs $value -c system-sphinx -n redhat-rhoam-3scale > $value.log ; done

  # zync
  for value in $(oc get po -n redhat-rhoam-3scale | grep zync | grep Running| awk '{print $1}'); do oc logs $value -n redhat-rhoam-3scale > $value.log ; done

  # marin3r
  for value in $(oc get po -n redhat-rhoam-3scale | grep marin3r | grep Running| awk '{print $1}'); do oc logs $value -n redhat-rhoam-3scale > $value.log ; done

  cd ../..
}

function keycloak_logs(){
  create_directory "keycloak"
  cd "$main_log_dir/keycloak"

  for value in $(oc get po -n redhat-rhoam-rhsso | grep keycloak | grep Running| awk '{print $1}'); do oc logs $value -c keycloak -n redhat-rhoam-rhsso > $value-rhsso.log ; done
  for value in $(oc get po -n redhat-rhoam-user-sso | grep keycloak | grep Running| awk '{print $1}'); do oc logs $value -c keycloak -n redhat-rhoam-user-sso > $value-user-sso.log ; done

  cd ../..
}

function tar_logdir(){
    tar -zcf - ./"$main_log_dir"
}

3scale_logs
keycloak_logs
#tar_logdir