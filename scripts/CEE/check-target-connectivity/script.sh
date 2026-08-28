#!/bin/bash

set -e
set -o nounset
set -o pipefail

# Configurable variables
PODNAME="check-target-connectivity"
NS="openshift-backplane-managed-scripts"

# Define the target (external service)
if [[ -z "${TARGET:-}" ]]; then
    echo 'Variable TARGET cannot be blank'
    exit 1
fi

if [[ -z "${PORT:-}" ]]; then
    echo 'Variable PORT cannot be blank'
    exit 1
fi

# Input sanity checks
if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
  echo "Error: Port must be a valid number."
  exit 1
fi

start_job(){
    CURRENTDATE=$(date +"%Y-%m-%d %T")
    echo "Job started at $CURRENTDATE"
    echo ".................................."
    echo
  }

finish_job(){
    CURRENTDATE=$(date +"%Y-%m-%d %T")
    echo
    echo ".................................."
    echo "Job finished at $CURRENTDATE"
}

#Create check pod
# shellcheck disable=SC1039
check_target_connectivity(){
  echo 'Starting check pod...'
  oc create -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${PODNAME}
  namespace: ${NS}
spec:
  privileged: false
  restartPolicy: Never
  containers:
  - name: check-target-connectivity
    image: quay.io/app-sre/srep-network-toolbox:latest
    image-pull-policy: Always
    command:
    - '/bin/bash'
    - '-c'
    - |-
      #!/bin/bash
      set -e
      # Check if the target is resolvable
      echo "Checking if the target ($TARGET) is resolvable..."
      if command -v nslookup > /dev/null; then
      nslookup "$TARGET"
      echo ".................................."
      else
        echo "'nslookup' command not available, skipping resolution check."
      fi

      # Check if the target is reachable via ICMP using ping
      echo "Pinging the target ($TARGET)..."
      sleep 5
      timeout 10 ping -c 3 "$TARGET" || echo "Ping failed or timed out. Continuing..."
      echo ".................................."

      # Check the routing to the target via traceroute with limits
      echo "Checking routing to the target ($TARGET) via traceroute..."
      if command -v traceroute > /dev/null; then
        timeout 5 traceroute -m 10 -w 1 -q 1 "$TARGET"
      else
        echo "'traceroute' command not available, skipping routing check."
      fi
      echo ".................................."
   
      # Check if target port is OPEN via nmap
      echo "Checking if port $PORT on target ($TARGET) is open using nmap..."
      sleep 5
      # Run nmap to check if the port is open
      if timeout 5 nmap -p "$PORT" "$TARGET" 2>&1 | grep -q "$PORT/tcp open"; then
        echo "Port $PORT is open on the target."
      else
        echo "Port $PORT is NOT open on the target."
      fi


      # Check DNS resolution using dig
      echo "Checking DNS resolution for $TARGET using dig..."
      sleep 5
      if command -v dig > /dev/null; then
        dig +short "$TARGET"
      else
        echo "'dig' command not available, skipping DNS check."
      fi
      
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      runAsUser: 1001
      capabilities:
        drop:
        - ALL
      seccompProfile:
        type: RuntimeDefault
EOF

  while [ "$(oc -n ${NS} get pod "${PODNAME}" -o jsonpath='{.status.phase}' 2>/dev/null)" != "Succeeded" ];
  do
    if [ "$(oc -n ${NS} get pod "${PODNAME}" -o jsonpath='{.status.phase}' 2>/dev/null)" == "Failed" ];
    then
      echo "The target connectivity check pod has failed. The logs are:"
      # Do not error if check pod is still in initialising state
      oc -n $NS logs "${PODNAME}" -c check-target-connectivity || true
      oc -n $NS delete pod "${PODNAME}" >/dev/null 2>&1
      exit 1
    fi
    sleep 30
  done

  oc -n $NS logs "${PODNAME}" -c check-target-connectivity
  oc -n $NS delete pod "${PODNAME}"  >/dev/null 2>&1

}

# Run all checks with retries and await timeout
main(){
  start_job
  check_target_connectivity
  finish_job
}

main


