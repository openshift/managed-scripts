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

# Detect the cloud provider, region, and platform from cluster metadata
detect_platform_and_region() {
    local region=""
    local cloud_provider=""
    local platform=""

    # Try to get cloud provider from cluster infrastructure
    cloud_provider=$(oc get infrastructure cluster -o jsonpath='{.status.platform}' 2>/dev/null || echo "")
    
    if [[ -z "$cloud_provider" ]]; then
        echo "$LOG_ERROR Could not determine cloud provider from cluster infrastructure" >&2
        return 1
    fi
    
    case "$cloud_provider" in
        "AWS")
            region=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.aws.region}' 2>/dev/null || echo "")
            platform="aws-classic"
            if [[ -n "$region" ]]; then
                echo "$region $platform"
                return 0
            else
                echo "$LOG_ERROR Could not determine AWS region" >&2
                return 1
            fi
            ;;
        "GCP")
            region=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.gcp.region}' 2>/dev/null || echo "")
            platform="gcp-classic"
            if [[ -n "$region" ]]; then
                echo "$region $platform"
                return 0
            else
                echo "$LOG_ERROR Could not determine GCP region" >&2
                return 1
            fi
            ;;
        *)
            echo "$LOG_ERROR Unsupported cloud provider: $cloud_provider" >&2
            return 1
            ;;
    esac
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
    
    # Check if binary is already at target location
    if [[ "$binary_path" != "$OSDCTL_BINARY" ]]; then
        mv "$binary_path" "$OSDCTL_BINARY"
    fi
    
    # Make sure it's executable
    chmod +x "$OSDCTL_BINARY"
    
    # Clean up
    rm -f "/tmp/osdctl.tar.gz"
}

# Run network verification in pod mode
run_network_verification() {
    local region platform region_platform_output
    
    # Get both region and platform in one call
    if ! region_platform_output=$(detect_platform_and_region); then
        echo "$LOG_ERROR Failed to detect platform and region"
        return 1
    fi
    
    region=$(echo "$region_platform_output" | cut -d' ' -f1)
    platform=$(echo "$region_platform_output" | cut -d' ' -f2)
    
    if [[ -z "$region" || -z "$platform" ]]; then
        echo "$LOG_ERROR Invalid region or platform detected. Region: '$region', Platform: '$platform'"
        return 1
    fi
    
    echo "$LOG_INFO Running network egress verification in pod mode..."
    echo "$LOG_INFO Using platform: $platform, region: $region"
    
    # Create a writable config directory for osdctl
    local config_dir="/tmp/osdctl-config"
    mkdir -p "$config_dir"
    
    # Set environment variables for osdctl configuration
    export TEMP_HOME="/tmp"
    export XDG_CONFIG_TEMP_HOME="$config_dir"
    export XDG_CACHE_TEMP_HOME="/tmp/cache"
    export XDG_DATA_TEMP_HOME="/tmp/data"
    
    # Run osdctl network verification
    local cmd_args=(
        "network"
        "verify-egress"
        "--pod-mode"
        "--platform" "$platform"
        "--skip-service-log"
        "--region" "$region"
        "--namespace" "$NAMESPACE"
    )
    
    echo "$LOG_INFO ============================================"
    echo "$LOG_INFO Network Verification Output:"
    echo "$LOG_INFO ============================================"
    
    # Run the command and capture both output and exit code
    local output exit_code
    output=$("$OSDCTL_BINARY" "${cmd_args[@]}" 2>&1)
    exit_code=$?
    
    # Display the output
    echo "$output"
    
    echo "$LOG_INFO ============================================"
    echo "$LOG_INFO End of Network Verification Output"
    echo "$LOG_INFO ============================================"
    
    if [[ $exit_code -ne 0 ]]; then
        echo "$LOG_ERROR Network verification failed with exit code: $exit_code"
        return 1
    fi
    
    echo "$LOG_INFO Network verification completed successfully"
}

# Cleanup function
cleanup() {
    rm -f "$OSDCTL_BINARY" "/tmp/osdctl.tar.gz"
}

# Set trap for cleanup
trap cleanup EXIT

main() {
    echo "$LOG_INFO Starting osdctl network verification script"
    
    if ! validate_environment; then
        echo "$LOG_ERROR Environment validation failed"
        exit 1
    fi
    
    if ! download_osdctl; then
        echo "$LOG_ERROR Failed to download osdctl binary"
        exit 1
    fi
    
    if ! run_network_verification; then
        echo "$LOG_ERROR Network verification failed"
        exit 1
    fi
    
    echo "$LOG_INFO Network verification script completed successfully"
    exit 0
}

main "$@" 