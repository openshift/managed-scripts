# Work In Progress

## Layout

1. Choose a worker node
- Set env var $nodename
- Capture node name through script argument given [WIP]

2. Open a debug session with $nodename [DONE]
- Run chroot /host
- Run toolbox
- Run sosreport in non interative mode

3. Capture last compacted file fenerated in `/host/var/tmp` 
4. Exit debug session [DONE]
5. Open new debug sesion, and copy the file to inside the backplane managedscript container [DONE]
6. Copy file to a SFTP server [DONE]
7. Provide instructions in how to use. [DONE]

## How to pull the collected sosreport from the SFTP Server.

1. Take note of the `Anonymous username` and `filename` from the the job output.

2. Access the [SFTP Token Portal](https://access.redhat.com/sftp-token/#/external).
- Use your Red Hat username. Eg. (rhn-support-hgomes)
- Click **Generate Token**

3. Open a local terminal and access SFTP server, as **password** use the generated token from step 2.
```
❯ sftp rhn-support-hgomes@sftp.access.redhat.com
rhn-support-hgomes@sftp.access.redhat.com's password:
```

4. Using the `anonymous username` and `filename` fetch the file. It will be saved in the local directory.
```
sftp> get anonymous/users/yqjqoccq/20231114AM-ip-10-0-178-83.eu-west-1.compute.internal-sosreport.tar.xz
```