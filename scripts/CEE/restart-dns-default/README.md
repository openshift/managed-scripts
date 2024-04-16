# Restart default dns pods in openshift-dns namespace

## Desctiption
 
This cript will trigger a rollout of deamonset, controlling dns default pods. Such action might be required when a customer is not able to perform it themself due to not having enough permissions etc, but dns-default pods need to be restarted.  

## Usage

```bash
ocm backplane managedjob create CEE/restart-dns-default -p NAMESPACE=openshift-dns
```



