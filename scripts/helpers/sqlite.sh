#!/usr/bin/env bash
# Prints the version for the "sqlite" image (variant $1 is accepted but unused -
# there is a single variant). The sqlite3 binary is copied from the pinned
# peakimages/sqlite tag in the Dockerfile, so that FROM line is the single source
# of truth: read the tag, drop the "-v<image-version>" suffix to get the SQLite
# version, and prepend "v". Renovate's docker manager bumps the Dockerfile tag.
set -euo pipefail

: "${1:?variant required}"

dockerfile="images/sqlite/Dockerfile"

# Match "peakimages/sqlite:<sqlite>-v<image>" and capture the leading SQLite version.
tag=$(grep -oE 'peakimages/sqlite:[0-9]+\.[0-9]+\.[0-9]+-v[0-9]+\.[0-9]+\.[0-9]+' "$dockerfile" | head -n1 | cut -d: -f2)

[ -n "$tag" ] || { echo "::error::sqlite: could not read peakimages/sqlite tag from $dockerfile" >&2; exit 1; }

printf 'v%s\n' "${tag%%-v*}"
