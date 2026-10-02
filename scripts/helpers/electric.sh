#!/usr/bin/env bash
# Prints the version for the "electric" image (variant $1 is accepted but unused -
# single variant). ElectricSQL removed its public Docker images, so the version is
# pinned to the last sync-service release in the preserved fork. Rebuilds only
# refresh the base images; the Electric version does not change. To move to a
# different release, bump this AND ELECTRIC_COMMIT in the Dockerfile together.
set -euo pipefail

: "${1:?variant required}"

printf '%s\n' '1.8.1'
