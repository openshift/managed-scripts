# Managed Backplane script for finding node restarts in the last X minutes


## Usage with managed-scripts

for usage with managed-scripts, the last min to check should be passed through the `last_min` variable.
Example:

```
ocm backplane managedjob create CSSRE/get-node-restarts -p last_min=120 # 120 minutes

# for setting log_level
ocm backplane managedjob create CSSRE/get-node-restarts -p last_min=120 -p log_level="debug"

# this will just take lastmin as 60 minutes if not specified
ocm backplane managedjob create CSSRE/get-node-restarts
```
