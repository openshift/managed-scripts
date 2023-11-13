# Work In Progress

## Layout

1. Choose a worker node
- Set env var $nodename
- Capture node name through script argument given
2. Open a debug session with $nodename
- Run chroot /host
- Run toolbox
- Run sosreport in non interative mode
```bash
sos report -k crio.all=on -k crio.logs=on --batch
```
3. Capture last compacted file fenerated in `/host/var/tmp`
```
ls -tA /host/var/tmp/*.tar.xz | head -1
```
4. Exit debug session
5. Open new debug sesion, and copy the file to inside the backplane managedscript container
```
oc debug node/my-cluster-node -- bash -c 'cat /host/var/tmp/sosreport-my-cluster-node-01234567-2020-05-28-eyjknxt.tar.xz' > /tmp/sosreport-my-cluster-node-01234567-2020-05-28-eyjknxt.tar.xz
```

6. Copy file to a bucket and extract from there?

### Commands

```
--- Choosing the worker node
oc get nodes -l node-role.kubernetes.io/worker="" --no-headers | awk '{print $1}' | sed 1q
--- 1st Debug session command
oc -n default debug node\/"$node" -- sh -c 'chroot /host toolbox sos report -k crio.all=on -k crio.logs=on --batch'
--- 2nd Debug session command
oc -n default debug node\/"$node" -- bash -c 'cat $(ls -tA /host/var/tmp/*.tar.xz | head -1)' > sosreport.tar.xz ;
```
