#!/usr/bin/env bash
# Prints the version for one variant of the "static" image (given as $1).
#
# minimal has no packages, so it uses a manually maintained image-definition
# version. The other variants are versioned by the Alpine package they ship:
# the version is read from the pinned Alpine branch's APKINDEX, the Alpine
# package revision (-rN) is dropped, and a "v" is prepended. Keep ALPINE_RELEASE
# in step with the alpine base tag in the Dockerfiles.
set -euo pipefail

# The image-definition version for the package-less "minimal" variant.
MINIMAL_VERSION="v1.0.0"

# renovate: datasource=docker depName=alpine
ALPINE_RELEASE="3.24"

variant="${1:?variant required}"

# Print the upstream version of an Alpine main package, "v"-prefixed, -rN dropped.
alpine_pkg_version() {
  local pkg="$1" ver
  # awk reads the whole APKINDEX (no early exit) so tar never gets SIGPIPE, which
  # pipefail would otherwise turn into a failure. One record per package anyway.
  ver=$(curl -sfL "https://dl-cdn.alpinelinux.org/alpine/v$ALPINE_RELEASE/main/x86_64/APKINDEX.tar.gz" \
    | tar -Ozx APKINDEX \
    | awk -v p="$pkg" 'BEGIN{RS="";FS="\n"}
        {n="";v="";for(i=1;i<=NF;i++){if($i~/^P:/)n=substr($i,3);if($i~/^V:/)v=substr($i,3)}
         if(n==p)out=v}
        END{if(out!="")print out}')
  [ -n "$ver" ] || { echo "::error::static: package '$pkg' not found in Alpine v$ALPINE_RELEASE" >&2; return 1; }
  printf 'v%s\n' "${ver%-r*}"
}

case "$variant" in
  minimal) printf '%s\n' "$MINIMAL_VERSION" ;;
  shell)   alpine_pkg_version busybox-static ;;
  curl)    alpine_pkg_version curl ;;
  certs)   alpine_pkg_version ca-certificates-bundle ;;
  *)       echo "::error::static: unknown variant '$variant'" >&2; exit 1 ;;
esac
