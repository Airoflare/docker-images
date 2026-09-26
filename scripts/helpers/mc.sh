#!/usr/bin/env bash
# Prints the version for the "mc" image (variant $1 is accepted but unused
# - single variant). MinIO archived the open-source mc and removed its images, so
# the version is pinned to the last open-source release. Rebuilds only refresh the
# Go toolchain and base image; the mc version does not change. To move to a
# different mc commit, bump this AND MC_COMMIT in the Dockerfile together.
set -euo pipefail

: "${1:?variant required}"

printf '%s\n' 'RELEASE.2025-08-13T08-35-41Z'
