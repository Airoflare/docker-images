#!/usr/bin/env bash
# Prints the version for one variant of the "aube" image (given as $1).
# Both variants (alpine, debian) ship the same aube release, so the variant is
# accepted but unused: the version is the latest aube GitHub release tag
# (e.g. v1.35.0). Needs gh with GH_TOKEN in the environment.
set -euo pipefail

: "${1:?variant required}"

gh api "repos/aubepkg/aube/releases/latest" --jq '.tag_name'
