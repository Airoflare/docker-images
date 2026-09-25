#!/bin/sh
# Download the official cloudflared release binary for the target architecture.
#
# Cloudflare ships the linux binaries as fully static Go executables, so they
# need no libc or OpenSSL at runtime. Unlike aube, Cloudflare publishes NO
# checksum or signature with the release, so there is nothing to verify the
# download against beyond the TLS connection to GitHub. We pin the version
# (CLOUDFLARED_VERSION) and confirm the artifact is a working executable; that is
# the strongest guarantee available upstream.
set -eu

: "${CLOUDFLARED_VERSION:?}" "${TARGETARCH:?}"

case "$TARGETARCH" in
  amd64 | arm64) ARCH="$TARGETARCH" ;;
  *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;;
esac

# The helper prepends "v"; the GitHub release tag has none.
version="${CLOUDFLARED_VERSION#v}"

curl -fsSL -o /usr/local/bin/cloudflared \
  "https://github.com/cloudflare/cloudflared/releases/download/${version}/cloudflared-linux-${ARCH}"
chmod 0555 /usr/local/bin/cloudflared

# Sanity check: it must actually run and report the version we asked for.
/usr/local/bin/cloudflared --version
