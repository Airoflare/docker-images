#!/usr/bin/env bash
# Prints the version for the "minio" image (variant $1 is accepted but unused -
# single variant). MinIO archived the open-source server and removed its images,
# so the version is pinned to the last open-source release. Rebuilds only refresh
# the Go toolchain and base image; the minio version does not change. To move to a
# different minio commit, bump this AND MINIO_COMMIT in the Dockerfile together.
set -euo pipefail

: "${1:?variant required}"

printf '%s\n' 'RELEASE.2025-10-15T17-29-55Z'
