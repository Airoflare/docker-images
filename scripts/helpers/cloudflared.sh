#!/usr/bin/env bash
# Prints the version for one variant of the "cloudflared" image (given as $1).
# Both variants (default, debug) ship the same cloudflared release, so the
# variant is accepted but unused. cloudflared tags upstream as e.g. 2026.9.3
# (no "v"); we prepend "v" to match this repo's tag convention. The Dockerfile
# strips it again for the download URL. Needs gh with GH_TOKEN in the environment.
set -euo pipefail

: "${1:?variant required}"

tag=$(gh api "repos/cloudflare/cloudflared/releases/latest" --jq '.tag_name')
printf 'v%s\n' "${tag#v}"
