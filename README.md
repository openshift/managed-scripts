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
