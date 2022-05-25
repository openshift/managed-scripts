# pcap-collector

This script creates a packet capture pod on a specified node and will capture a tcpdump for a given time.
The packet capture pod runs in the `openshift-backplane-managed-scripts` namespace.

__NOTE:__ backplane cli >= 0.0.23 is needed.

## Usage

Parameters:
- TIME: In seconds. Must be less than or equal to 900 (15 mins)
- NODE: The node to run the packet capture on.

```bash
# Capture traffic on node ip-10-0-253-170.ap-southeast-2.compute.internal for 10 mins
ocm backplane managedjob create CEE/pcap-collector -p TIME=600 -p NODE=ip-10-0-253-170.ap-southeast-2.compute.internal

# Getting the resulting pcap file
# The response is a gzipped pcap file.
ocm backplane managedjob logs <JOBNAME> | gunzip > node.pcap
```



