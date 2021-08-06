# Backplane Managed scripts

This is a repository storing OpenShift Dedicated managed scripts.

## Repository layout

The repository lays out like this

```text
 .
├──  hack
│  ├──  app_sre_build_deploy.sh
│  ├──  app_sre_build_push.sh
│  ├──  app_sre_pr_check.sh
│  ├──  build
│  │  └──  Dockerfile
│  ├──  Makefile
│  ├──  project.mk
│  └──  standard.mk
├──  LICENSE
├──  README.md
├──  CEE # Red Hat Managed Roles
│     └──  ...
└──  SREP # Red Hat Managed Roles
   └──  example # Script Name
      ├──  metadata.yaml # Metadata of the script
      └──  script.sh # Actual script file
```

`hack` contains various helper script for CI/CD tooling and building

Each Red Hat managed role has a dedicated directory under root and each of the contains any number
of scripts.

Each script directory has to contain a `metadata.yaml` file, the format of the metadata file is
documented below.

Besides the `metadata.yaml` file, each directory should contain a single script file, written in one of
the supported languages.

## `metadata.yaml`

`metadata.yaml` shall pass validation against `metadata.schema.json` see [here](https://json-schema.org/) for more details



