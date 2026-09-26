#!/usr/bin/env bash
# Prints the version for the "castlemock" image (variant $1 is accepted but
# unused - single variant). Castle Mock is archived and its Docker images are
# being deleted, so the version is pinned to the last open-source release.
# Rebuilds only refresh the JRE base and JDK toolchain; the Castle Mock version
# does not change. To move to another release, bump this AND CASTLEMOCK_COMMIT in
# the Dockerfile together.
set -euo pipefail

: "${1:?variant required}"

printf '%s\n' 'v1.68'
