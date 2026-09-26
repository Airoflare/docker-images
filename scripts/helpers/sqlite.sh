#!/usr/bin/env bash
# Prints the version for the "sqlite" image (variant $1 is accepted but unused -
# there is a single variant). The image is versioned by the SQLite version in the
# pinned Alpine branch: read the sqlite package version from the APKINDEX, drop
# the Alpine -rN revision, and prepend "v". Keep ALPINE_RELEASE in step with the
# alpine base tag in the Dockerfile.
set -euo pipefail

: "${1:?variant required}"

# renovate: datasource=docker depName=alpine
ALPINE_RELEASE="3.24"

# awk reads the whole APKINDEX (no early exit) so tar never gets SIGPIPE.
ver=$(curl -sfL "https://dl-cdn.alpinelinux.org/alpine/v$ALPINE_RELEASE/main/x86_64/APKINDEX.tar.gz" \
  | tar -Ozx APKINDEX \
  | awk 'BEGIN{RS="";FS="\n"}
      {n="";v="";for(i=1;i<=NF;i++){if($i~/^P:/)n=substr($i,3);if($i~/^V:/)v=substr($i,3)}
       if(n=="sqlite")out=v}
      END{if(out!="")print out}')

[ -n "$ver" ] || { echo "::error::sqlite: package not found in Alpine v$ALPINE_RELEASE" >&2; exit 1; }
printf 'v%s\n' "${ver%-r*}"
