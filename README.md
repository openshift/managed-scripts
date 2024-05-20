# Backplane Managed scripts

This is a repository storing OpenShift Dedicated managed scripts.

## Repository layout

`scripts` folder contains various scripts used by different teams.

`hack` contains various helper script for CI/CD tooling and building.

Each Red Hat managed role has a dedicated directory under root and each of the contains any number
of scripts.

Each script directory has to contain a `metadata.yaml` file, the format of the metadata file is
documented below.

Besides the `metadata.yaml` file, each directory should contain a single script file, written in one of
the supported languages.

## `metadata.yaml`

All `metadata.yaml` shall pass validation against `hack/metadata.schema.json` see [here](https://json-schema.org/) for more details.

Note: The `name` in the `metadata.yaml` must be the same as the directory name where the `metadata.yaml` file resides.

### Validation methods:

1. In order to check all `metadata.yaml` from all scripts, you can run the command below from your managed-scripts root directory:

    `make validation`

2. To run the validation just for specifics scripts, you can use the command below parsing the scripts as arguments:

    `make validation SCRIPTS="<script1> <scriptN>"`

    example:

    `make validation SCRIPTS="under-replicated-partition rolling-restart-broker"`


## Release Cycle

Managed Scripts has the following release cycle:

### Staging:

The staging environment is pinned to consume the main branch of the managed-scripts repository.

### Production:

Once every 3 weeks.

In case you have changes that have immediate impact and would need an immediate promotion, please reach out to:
Managed-scripts team (alias : @managed-scripts) in #sd-ims-backplane slack channel 
