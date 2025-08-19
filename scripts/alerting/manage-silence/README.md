# manage-silence script

## Purpose

The script is used to ease the handling of a single cluster silence. 
It supports 3 different usecases : 
* Setting a silence in alertmanager for the cluster
* Clearing all currently set silences
* List the on-going silence(s) set for the cluster

## Parameters and usage 
### Script usage

```bash
usage: script.sh [--create-silence --username <username> {--silence-duration <duration>} {--silence-comment <comment>}|--clear-silences|--list-silences]
Default: list the existing silences
  --clear-silences   : clear all active silences
  --list-silence     : list the currently active  (default action)
  --create-silence   : create a silence 
  --silence-duration : duration in min of the silence when creation one. For silence creation only (for --create-silence only ; optional - default is 60)
  --username         : name of the user setting the silence (for --create-silence only ; mandatory)
  --silence-comment  : comment for the silence (for --create-silence only ; optional)
```

When creating a new silence, `--username` is mandatory as the backplane user which can be retrieved automatically doesn't help a lot in case of context/information needed from the logger. 

`--clear-silences` and `--list-silences` don't require additional options. 

### Usage with managed-scripts

For usage with managed-scripts, the options need to be passed through the `SCRIPT_PARAMETERS` environment variable. Here are some examples : 

```bash
ocm backplane managedjob create alerting/manage-silence -p SCRIPT_PARAMETERS="--create-silence --silence-duration 20  --silence-comment \"This is a test silence\" "

ocm backplane managedjob create alerting/manage-silence -p SCRIPT_PARAMETERS="--create-silence --silence-duration 20  --silence-comment OHSS-xxxx "

ocm backplane managedjob create alerting/manage-silence -p SCRIPT_PARAMETERS="--clear-silences "

# This will list the existing silences
ocm backplane managedjob create alerting/manage-silence 
```