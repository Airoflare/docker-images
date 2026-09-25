#!/bin/sh
# Download the official cloudflared release binary for the target architecture
# and verify it against the SHA256 checksum Cloudflare publishes in the release.
#
# cloudflared ships as a fully static Go binary (no libc/OpenSSL at runtime).
# Cloudflare does not sign the binaries with sigstore the way aube does, but it
# lists a SHA256 for every asset in the GitHub release body. We read that, check
# our download against it, and fail on any mismatch.
set -eu

: "${CLOUDFLARED_VERSION:?}" "${TARGETARCH:?}"

case "$TARGETARCH" in
  amd64 | arm64) ARCH="$TARGETARCH" ;;
  *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;;
esac

version="${CLOUDFLARED_VERSION#v}"   # the helper prepends "v"; the release tag has none
asset="cloudflared-linux-${ARCH}"
repo="cloudflare/cloudflared"
api="https://api.github.com/repos/${repo}/releases/tags/${version}"

# Authenticate the API call when a token is mounted (CI), so shared-runner IPs do
# not hit the unauthenticated GitHub API rate limit. Optional for local builds.
if [ -s /run/secrets/github_token ]; then
  meta=$(curl -fsSL -H "Authorization: Bearer $(cat /run/secrets/github_token)" "$api")
else
  meta=$(curl -fsSL "$api")
fi

# Expected checksum from the release body's "SHA256 Checksums:" list.
expected=$(printf '%s' "$meta" | jq -r '.body' | grep -E "^${asset}: " | awk '{print $2}')
case "$expected" in
  [0-9a-f][0-9a-f]*) : ;;
  *) echo "No SHA256 checksum for ${asset} in ${repo} ${version}" >&2; exit 1 ;;
esac

curl -fsSL -o /usr/local/bin/cloudflared \
  "https://github.com/${repo}/releases/download/${version}/${asset}"

echo "${expected}  /usr/local/bin/cloudflared" | sha256sum -c -
chmod 0555 /usr/local/bin/cloudflared

# Sanity check: it must actually run.
/usr/local/bin/cloudflared --version
