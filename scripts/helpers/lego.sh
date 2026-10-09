#!/usr/bin/env bash
# Prints the version for one variant of the "lego" image (given as $1).
# Both variants (default, debug) ship the same lego release, so the variant is
# accepted but unused. lego tags upstream as e.g. v5.5.2; the "v" is stripped
# and added again so the output always has exactly one. Needs gh with GH_TOKEN
# in the environment.
set -euo pipefail

: "${1:?variant required}"

tag=$(gh api "repos/go-acme/lego/releases/latest" --jq '.tag_name')
printf 'v%s\n' "${tag#v}"
