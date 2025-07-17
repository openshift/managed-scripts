# Check Target Connectivity from Openshift Cluster Script

## Purpose

This script is designed to perform multiple checks to troubleshoot target connectivity from OpenShift cluster 

  Performed checks:
  - DNS resolution check via nslookup: $ nslookup "$TARGET"
  - DNS resolution via Dig: $ dig +short "$TARGET"
  - ICMP check via ping: $ timeout 10 ping -c 3 "$TARGET"
  - Routing Check via traceroute: $ timeout 5 traceroute -m 10 -w 1 -q 1 "$TARGET"
  - Check Target Port is Open via nmap: $ timeout 5 nmap -p "$PORT" "$TARGET" 2>&1 | grep -q "$PORT/tcp open"

  Notes: 
  - Each check awaits for 5 seconds before starting to minimize impact on the network. 

## Usage

Parameters:
- TARGET: Target host
- PORT: Target port

```bash
ocm backplane managedjob create CEE/check-target-connectivity -p TARGET={target} -p PORT={port}
```

## Important Notes

- The script utilizes the `oc` command-line tool, and the user running the script should have the necessary permissions to access the cluster.
- This script is read-only and does not modify any resources in the cluster.
- Ensure that the required tools (`oc`) are available in the environment where the script is executed.
