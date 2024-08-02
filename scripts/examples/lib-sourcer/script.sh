#!/usr/bin/env bash
set -euo pipefail

# All files in scripts end up at /managed-scripts in the actual docker container
# i.e.
# managed-scripts/scripts/examples/lib-sourcer/lib.sh
# becomes
# shellcheck source=/dev/null
source /managed-scripts/lib/examples/lib.sh

echo_import
