# Backplane Managed scripts

This is a repository storing OpenShift Dedicated managed scripts.

## Repository layout

`scripts` folder contains various scripts used by different teams.

`hack` contains various helper script for CI/CD tooling and building

Each Red Hat managed role has a dedicated directory under root and each of the contains any number
of scripts.

Each script directory has to contain a `metadata.yaml` file, the format of the metadata file is
documented below.

Besides the `metadata.yaml` file, each directory should contain a single script file, written in one of
the supported languages.

## `metadata.yaml`

All `metadata.yaml` shall pass validation against `hack/metadata.schema.json` see [here](https://json-schema.org/) for more details

## Local Development

To test your metadata.yaml and script file, you can render the resources as yaml and deploy them to your OpenShift cluster.

First, build the image and publish it in a container registry:

```
podman build . -t quay.io/my-user/managed-scripts
podman push quay.io/my-user/managed-scripts # Make sure the repo is public so you can use it in your cluster.
```

Render Kubernetes resources with the helper tool:

```
# Local environment variables will be rendered as requested by the script
export var1=val1

# Invoke helper tool
go run dev/getk8s -i quay.io/my-user/managed-scripts scripts/SREP/example > example-resources.yaml

# Create resources. Make sure your user has the necessary privileges to create the resources
oc apply -f example-resources.yaml

oc get po -n backplane-dev
```