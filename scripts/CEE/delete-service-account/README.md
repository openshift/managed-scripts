# Delete a service account in the default namespace

## Desctiption
 
This script will remove a service account that was deployed in the default namespace as a part of custom workload. The service account needs to be passed as an argument SERVICE_ACCOUNT 

## Usage

```bash
ocm backplane managedjob create CEE/delete-service-account -p SERVICE_ACCOUNT=service_account_name
```



