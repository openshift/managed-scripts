#!/bin/bash
#
# Description: Downloads latest osdctl binary and runs network egress verification in pod mode.

set -euo pipefail

# Global variables
readonly NAMESPACE="openshift-network-diagnostics"
readonly OSDCTL_REPO="openshift/osdctl"
readonly OSDCTL_BINARY="/tmp/osdctl"
readonly LOG_INFO="INFO:"
readonly LOG_ERROR="ERROR:"
readonly LOG_WARN="WARNING:"

# Validate environment for Kubernetes access
validate_environment() {
    echo "$LOG_INFO Validating environment..."
    
    # Check if running in a pod with service account
    if [[ -f "/var/run/secrets/kubernetes.io/serviceaccount/token" ]]; then
        echo "$LOG_INFO Running in pod with ServiceAccount token"
        return 0
    fi
    
    # Check if oc is available and logged in
    if command -v oc &> /dev/null; then
        if oc whoami &> /dev/null; then
            echo "$LOG_INFO Logged into OpenShift cluster via oc"
            return 0
        fi
    fi
    
    echo "$LOG_ERROR Must be running in a pod with ServiceAccount token or logged into OpenShift cluster"
    return 1
}

# Detect the current region from cluster metadata
detect_region() {
    local region=""
    
    echo "$LOG_INFO Attempting to detect AWS region..."
    
    # Try to get region from cluster infrastructure
    if command -v oc &> /dev/null; then
        region=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.aws.region}' 2>/dev/null || echo "")
        if [[ -n "$region" ]]; then
            echo "$LOG_INFO Detected region from cluster infrastructure: $region"
            echo "$region"
            return 0
        fi
    fi
    
    echo "$LOG_ERROR Could not auto-detect region"
    return 1
}

# Download the latest osdctl binary from GitHub
download_osdctl() {
    echo "$LOG_INFO Downloading latest osdctl binary..."
    
    # Get the latest release URL
    local latest_url
    latest_url=$(curl -s "https://api.github.com/repos/$OSDCTL_REPO/releases/latest" | \
                 grep -o '"browser_download_url": "[^"]*Linux_x86_64[^"]*"' | \
                 cut -d '"' -f 4)
    
    if [[ -z "$latest_url" ]]; then
        echo "$LOG_ERROR Failed to get latest osdctl release URL"
        return 1
    fi
    
    echo "$LOG_INFO Downloading from: $latest_url"
    
    # Download and extract the binary
    curl -L -o "/tmp/osdctl.tar.gz" "$latest_url"
    tar -xzf "/tmp/osdctl.tar.gz" -C /tmp
    
    # Find the extracted binary (it might be in a subdirectory)
    local binary_path
    binary_path=$(find /tmp -name "osdctl" -type f -executable | head -1)
    
    if [[ -z "$binary_path" ]]; then
        echo "$LOG_ERROR Could not find osdctl binary after extraction"
        return 1
    fi
    
    # Move to standard location and make executable
    mv "$binary_path" "$OSDCTL_BINARY"
    chmod +x "$OSDCTL_BINARY"
    
    echo "$LOG_INFO Successfully downloaded osdctl binary"
    
    # Clean up
    rm -f "/tmp/osdctl.tar.gz"
}

# Run network verification in pod mode
run_network_verification() {
    local region
    region=$(detect_region)
    
    echo "$LOG_INFO Running network egress verification in pod mode..."
    echo "$LOG_INFO Using region: $region"
    echo "$LOG_INFO Using namespace: $NAMESPACE"
    
    # Run osdctl network verification
    local cmd_args=(
        "network"
        "verify-egress"
        "--pod-mode"
        "--skip-service-log"
        "--region" "$region"
        "--namespace" "$NAMESPACE"
        "--debug"
    )
    
    echo "$LOG_INFO Executing: $OSDCTL_BINARY ${cmd_args[*]}"
    "$OSDCTL_BINARY" "${cmd_args[@]}"
}

# Cleanup function
cleanup() {
    echo "$LOG_INFO Cleaning up temporary files..."
    rm -f "$OSDCTL_BINARY" "/tmp/osdctl.tar.gz"
}

# Set trap for cleanup
trap cleanup EXIT

main() {
    echo "$LOG_INFO Starting osdctl network verification script"
    
    validate_environment
    download_osdctl
    run_network_verification
    
    echo "$LOG_INFO Network verification completed successfully"
    exit 0
}

main "$@" 