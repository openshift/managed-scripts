#!/bin/bash
#
# Description: Runs network egress verification in pod mode using the pre-installed osdctl binary.

set -euo pipefail

# Global variables
readonly NAMESPACE="openshift-network-diagnostics"
readonly OSDCTL_BINARY="osdctl"
readonly LOG_INFO="INFO:"
readonly LOG_ERROR="ERROR:"
readonly LOG_WARN="WARNING:"

# Global variables set by detect_platform_and_region()
REGION=""
PLATFORM=""
HCP_CLUSTER=false
ZERO_EGRESS=false

# Parse script parameters (follows managed-scripts convention)
parse_script_parameters() {
    # If SCRIPT_PARAMETERS is not set, nothing to parse
    if [[ -z "${SCRIPT_PARAMETERS:-}" ]]; then
        return 0
    fi
    
    # Split SCRIPT_PARAMETERS into array
    IFS=' ' read -r -a ARG_ARRAY <<< "${SCRIPT_PARAMETERS}"
    
    # Parse arguments
    for ARG in "${ARG_ARRAY[@]}"; do
        if [[ "$ARG" == "--hcp" ]]; then
            HCP_CLUSTER=true
        elif [[ "$ARG" == "--zero-egress" ]]; then
            ZERO_EGRESS=true
        elif [[ "$ARG" == "-h" || "$ARG" == "--help" ]]; then
            echo "Usage: SCRIPT_PARAMETERS=\"[--hcp] [--zero-egress]\""
            echo "  --hcp           Specify that this is an HCP (Hosted Control Plane) cluster"
            echo "  --zero-egress   Specify that this is an HCP cluster with zero egress configuration"
            exit 0
        else
            echo "$LOG_ERROR Unknown parameter: $ARG"
            echo "$LOG_INFO Valid parameters: --hcp, --zero-egress, --help"
            exit 1
        fi
    done
}

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



# Detect the cloud provider and platform from cluster metadata
detect_platform_and_region() {
    local cloud_provider=""

    # Try to get cloud provider from cluster infrastructure
    cloud_provider=$(oc get infrastructure cluster -o jsonpath='{.status.platform}' 2>/dev/null || echo "")
    
    if [[ -z "$cloud_provider" ]]; then
        echo "$LOG_ERROR Could not determine cloud provider from cluster infrastructure" >&2
        return 1
    fi
    
    case "$cloud_provider" in
        "AWS")
            if [[ "$ZERO_EGRESS" == true ]]; then
                PLATFORM="aws-hcp-zeroegress"
            elif [[ "$HCP_CLUSTER" == true ]]; then
                PLATFORM="aws-hcp"
            else
                PLATFORM="aws-classic"
            fi
            
            REGION=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.aws.region}' 2>/dev/null || echo "")
            if [[ -z "$REGION" ]]; then
                echo "$LOG_ERROR Could not determine AWS region" >&2
                return 1
            fi
            ;;
        "GCP")
            PLATFORM="gcp-classic"
            ;;
        *)
            echo "$LOG_ERROR Unsupported cloud provider: $cloud_provider" >&2
            return 1
            ;;
    esac
}

# Run network verification in pod mode
run_network_verification() {
    # Get platform and region (if applicable)
    if ! detect_platform_and_region; then
        echo "$LOG_ERROR Failed to detect platform"
        return 1
    fi
    
    if [[ -z "$PLATFORM" ]]; then
        echo "$LOG_ERROR Invalid platform detected: '$PLATFORM'"
        return 1
    fi
    
    echo "$LOG_INFO Running network egress verification in pod mode..."
    if [[ -n "$REGION" ]]; then
        echo "$LOG_INFO Using platform: $PLATFORM, region: $REGION"
    else
        echo "$LOG_INFO Using platform: $PLATFORM"
    fi
    
    # Create a writable config directory for osdctl
    local config_dir="/tmp/osdctl-config"
    mkdir -p "$config_dir"
    
    # Set environment variables for osdctl configuration
    export HOME="/tmp"
    export XDG_CONFIG_HOME="$config_dir"
    export XDG_CACHE_HOME="/tmp/cache"
    export XDG_DATA_HOME="/tmp/data"
    
    # Build command arguments
    local cmd_args=(
        "network"
        "verify-egress"
        "--pod-mode"
        "--platform" "$PLATFORM"
        "--skip-service-log"
        "--namespace" "$NAMESPACE"
    )
    
    # Add region flag only for AWS
    if [[ -n "$REGION" ]]; then
        cmd_args+=("--region" "$REGION")
    fi
    
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

main() {
    echo "$LOG_INFO Starting osdctl network verification script"
    
    # Parse script parameters
    parse_script_parameters
    
    if ! validate_environment; then
        echo "$LOG_ERROR Environment validation failed"
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