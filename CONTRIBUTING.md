<h1>Creating a backplane-managed script for ROSA/OSD clusters</h1>

<h3>Overview</h3>
Backplane Scripts allows backplane users to run pre-defined scripts that require privileged permissions on OSD/ROSA clusters.

<h3>Terminology</h3>

- <h5>Managed Script</h5>A script file and its associate metadata file, stored in the managed-scripts GitHub repo.
- <h5>Managed Job</h5>A running instance of the Managed Script in an OSD/ROSA cluster.

<h3>Prerequisites</h3>

The following are prerequisites to create/test/deploy new scripts.

1. VPN connectivity
2. [OCM CLI Binary](https://github.com/openshift-online/ocm-cli)
3. [Backplane CLI Binary](https://source.redhat.com/groups/public/sre/wiki/setup_backplane_cli) 
4. Access to the [Stage API](https://api.stage.backplane.openshift.com)
5. [GitHub](https://github.com) account
6. Any kind of advanced text editors like [VS Code](https://code.visualstudio.com/)

All the pre-created scripts are available [here](https://github.com/openshift/managed-scripts/tree/main/scripts) for reference.

---

<h3>Creating a new script</h3>

1. Create a fork of the [Managed Scripts GitHub Repo](https://github.com/openshift/managed-scripts). Please refer to [Fork a repo](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) for more information.
   
2. Create a new branch (Don’t use the main/master branch to send the PR), assign a name that represents the subject or that is a feature. Refer to [GitHub - How to create a new branch](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-and-deleting-branches-within-your-repository).
   
4. With the new fork created, clone the repository from your new fork URL (Use a folder of your preference to place the git repository):
   ~~~
   $ git clone https://github.com/<git_user>/managed-scripts.git
   ~~~

5. Create a new folder to place the new script:
   ~~~
      
   $ cd <path-to-folder>/managed-scripts/scripts/CEE
   $ mkdir -p new-script
   $ tree view -d .
   
   ├── check-tech-preview-features
   <...>
   ├── new-script    <<<< NEW FOLDER
   ~~~
   
6. Inside the new folder, create metadata.yaml file according to the Metadata Schema defined [here](https://github.com/openshift/managed-scripts/blob/main/hack/metadata.schema.json). A filled-in example could be [this](https://github.com/openshift/managed-scripts/blob/main/scripts/CEE/etcd-health-check/metadata.yaml). This file is what translates the RBAC permissions to the script commands. Specify allowedGroups like CEE,SREP,etc. 
**Note**: _Do not use cluster-admin RBAC, like verbs/object [*]. Prefer the least privileged approach._

7. Create the script.sh.
   ~~~
   $ tree view new-script
   new-script
   ├── metadata.yaml
   └── script.sh
   ~~~
   
---

<h3>Testing the script</h3>

1. Make sure you are using the Stage API
  ~~~
  $ ocm backplane config set url https://api.stage.backplane.openshift.com
  $ ocm backplane config get url

  Output: 
  url: https://api.stage.backplane.openshift.com
  ~~~

2. Connect to a Stage cluster in order to test the new script
  ~~~
  $ ocm backplane login <stage-cluster-id>
  ~~~

3. From inside the new directory, run the testjob command
  ~~~
  $ ocm backplane testjob create [-p var1=val1]
    Test job openshift-job-dev-7m755 created successfully    
    Run "ocm backplane testjob get openshift-job-dev-7m755" for details
    Run "ocm backplane testjob logs openshift-job-dev-7m755" for job logs
  ~~~

4. To check the job status
  ~~~
  $ ocm backplane testjob get openshift-job-dev-7m755
     TestId: openshift-job-dev-7m755, Status: Succeeded
  ~~~

5. To get the logs
  ~~~
  $ ocm backplane testjob logs openshift-job-dev-7m755
  ~~~

---

<h3>Deploy the script into production</h3>

- Remember PRs must be created from a non-main/master branch.
- To have the script available to clusters in production API, a PR must be opened and merged by the SRE team. SRE will review the code and further discussions may be needed. For any inquiry, the slack channel `#sd-ims-backplane` can be used by tagging `@backplane-team`.
- Once the PR is fully accepted, the merge should happen automatically bi-weekly on Monday during APAC afternoon hours.
- To validate that the script is available:
    - Connect to the [Backplane Production API](https://api.backplane.openshift.com),
    - Log in to a cluster,
    - List the managed scripts using the below command
      > $ ocm backplane script list




