# Restart default dns pods in openshift-dns namespace

## Desctiption
 
This script will trigger a rollout of daemonset, controlling dns default pods. Such action might be required when a customer is not able to perform it themself due to not having enough permissions etc, but dns-default pods need to be restarted.  

## Usage

```bash
ocm backplane managedjob create networking/restart-dns-default
```



