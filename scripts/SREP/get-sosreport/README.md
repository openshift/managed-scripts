# Get SOS Report script

This will script will generate a sosreport, copy to the container volume the push into Red Hat SFTP server.

- Add the node name as parameter.
Example:
```
ocm backplane managedjob create SREP/get-sosreport -p NODE="ip-10-0-178-83.eu-west-1.compute.internal"
```

## How to pull the collected sosreport from Red Hat SFTP Server.

1. Take note of the `Anonymous username` and `filename` from the job output.

2. Access the [SFTP Token Portal](https://access.redhat.com/sftp-token/#/external).
- Use your Red Hat username. Eg. (rhn-support-hgomes)
- Click **Generate Token**

3. Open a local terminal and access the SFTP server. Use the generated token from step 2 as the password.
```
❯ sftp rhn-support-hgomes@sftp.access.redhat.com
rhn-support-hgomes@sftp.access.redhat.com's password:
```

4. Using the `anonymous username` and `filename` fetch the file. It will be saved in the local directory.
```
sftp> get anonymous/users/yqjqoccq/20231114AM-ip-10-0-178-83.eu-west-1.compute.internal-sosreport.tar.xz
```