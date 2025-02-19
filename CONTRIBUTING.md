<h1>Creating a backplane-managed script for ROSA/OSD clusters</h1>

<h3>Overview</h3>:

Backplane Scripts allows backplane users to run pre-defined scripts that require privileged permissions on OSD/ROSA clusters.

<h3>Terminology</h3>:

Managed Script: A script file and its associate metadata file, stored in the managed-scripts GitHub repo.

Managed Job: A running instance of the Managed Script in an OSD/ROSA cluster.

Prerequisites:

The following are prerequisites to create/test/deploy new scripts.

VPN connectivity
ocm-cli 
backplane-cli 
Access to the Stage API (https://api.stage.backplane.openshift.com)
Git
Code editors like VS Code which may help when coding

<h3>Check available scripts here</h3>.


Creating a new script
Create a fork of the Managed Scripts repository. Please refer to Fork a repo for more information.
Create a new branch (Don’t use the main/master branch to send the PR), assign a name that represents the subject or that is a feature. Refer to GitHub - How to create a new branch.
With the new fork created, clone the repository from your new fork URL (Use a folder of your preference to place the git repository):
            
            $ git clone https://github.com/<git_user>/managed-scripts.git

Create a new folder to place the new script:
      
           $ cd <path-to-folder>/managed-scripts/scripts/CEE
           $ mkdir -p new-script
           $ tree view -d .
   
          ├── check-tech-preview-features
           <...>
          ├── new-script    <<<< NEW FOLDER

Inside the new folder, create metadata.yaml file according to the Metadata Schema defined here. A filled-in example could be this. This file is what translates the RBAC permissions to the script commands. Specify allowedGroups like CEE,SREP,etc.

 Note: Do not use cluster-admin RBAC, like verbs/object [*]. Prefer the least privileged approach.

Create the script.sh.
            $ tree view new-script
             new-script
            ├── metadata.yaml
            └── script.sh

Testing the script
Make sure you are using the Stage API:
$ ocm backplane config set url https://api.stage.backplane.openshift.com
$ ocm backplane config get url
   url: https://api.stage.backplane.openshift.com


Connect to a Stage cluster in order to test the new script:
$ ocm backplane login <stage-cluster-id>


From inside the new directory, run the testjob command:
$ ocm backplane testjob create [-p var1=val1]
   Test job openshift-job-dev-7m755 created successfully    
   Run "ocm backplane testjob get openshift-job-dev-7m755" for details
   Run "ocm backplane testjob logs openshift-job-dev-7m755" for job logs


To check the job status:
$ ocm backplane testjob get openshift-job-dev-7m755
   TestId: openshift-job-dev-7m755, Status: Succeeded


To get the logs:
$ ocm backplane testjob logs openshift-job-dev-7m755

Deploy the script into production:
Remember PRs must be created from a non-main/master branch.
To have the script available to clusters in production API, a PR must be opened and merged by the SRE team. SRE will review the code and further discussions may be needed. For any inquiry, the slack channel #sd-ims-backplane can be used by tagging @backplane-team.
Once the PR is fully accepted, the merge should happen automatically bi-weekly on Monday during APAC afternoon hours.
To validate that the script is available, connect to the Backplane Production API (https://api.backplane.openshift.com), log in to a cluster, and list the managed scripts using the below command.
$ ocm backplane script list




