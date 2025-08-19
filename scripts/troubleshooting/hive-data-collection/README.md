# Hive Data Collection

## Description

This script is responsible for collecting data from Hive clusters in order to troubleshoot/debug cluster provisioning delays.

NOTE: This script is intended for Production only.

## Usage

For this script to run, it is required to collect the internal cluster ID. For that, please run the commands below by informing the external cluster ID:

```bash
ECLUSTERID="<External ID>"
```
```bash
ICLUSTERID=$(ocm describe cluster $ECLUSTERID --json | jq -r '.id')
```

Before running the managed-script, log in to the Hive cluster by using the command below:

```bash
$ ocm backplane login $ECLUSTERID --manager
```

After logging in, the command below can be run to collect the Hive data. Please inform the "ACTION" to be executed: "full" for full data collect, or by specifying the information do be collected:

```bash
ocm backplane managedjob create troubleshooting/hive-data-collection -p CLUSTER_ID=$ICLUSTERID -p ACTION="<full|clusterdeployment|clustersync|pods|events>"
```