# Managed Backplane script for finding node restarts in the last X minutes


## Usage with managed-scripts

for usage with managed-scripts, the last min to check should be passed through the `LAST_MIN` variable.
Example:

```
ocm backplane managedjob create LPSRE/get-node-restarts -p LAST_MIN=120 # 120 minutes

# for setting log_level
ocm backplane managedjob create LPSRE/get-node-restarts -p LAST_MIN=120 -p LOG_LEVEL="debug"

# this will just take lastmin as 60 minutes if not specified
ocm backplane managedjob create LPSRE/get-node-restarts
```
