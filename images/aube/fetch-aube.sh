#!/bin/sh
# Download aube's prebuilt static-musl binaries and verify them before use.
#
# aube publishes a sigstore bundle (packslip.sigstore.json) that signs an
# in-toto statement listing every release artifact's sha256/sha512. We bootstrap
# a pinned cosign, then check the tarball we fetched is one of those signed
# subjects and that the bundle was signed by aube's own release workflow. Without
# this, `curl | tar` would trust whatever GitHub happened to serve.
set -eu

: "${AUBE_VERSION:?}" "${TARGETARCH:?}"

# Pinned cosign, used only to verify the download.
# renovate: datasource=github-releases depName=sigstore/cosign
COSIGN_VERSION=3.1.3
COSIGN_SHA_amd64=4629c757b7618056f8ddd7e2625ae9fdd94c0372a65049520bc7d9df9efc7f71
COSIGN_SHA_arm64=c5d324e091826b0d7a78eb16fef316450b4eb9aaec045611c08ba06f5e73220a

# aube's release workflow is the only trusted signer of the bundle.
AUBE_ID_RE='^https://github.com/aubepkg/aube/\.github/workflows/[^@]+@refs/heads/main$'
AUBE_OIDC='https://token.actions.githubusercontent.com'
AUBE_PREDICATE='https://packslip.dev/release/v1'

case "$TARGETARCH" in
  amd64) ARCH=x86_64;  cosign_sha="$COSIGN_SHA_amd64" ;;
  arm64) ARCH=aarch64; cosign_sha="$COSIGN_SHA_arm64" ;;
  *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;;
esac

cd /tmp

# Bootstrap cosign, pinned by digest.
curl -fsSL -o cosign \
  "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-${TARGETARCH}"
echo "${cosign_sha}  cosign" | sha256sum -c -
chmod +x cosign

base="https://github.com/aubepkg/aube/releases/download/${AUBE_VERSION}"
tarball="aube-${AUBE_VERSION}-${ARCH}-unknown-linux-musl.tar.gz"
curl -fsSL -o "$tarball" "$base/$tarball"
curl -fsSL -o packslip.sigstore.json "$base/packslip.sigstore.json"

# Fails unless the tarball's digest is a signed subject in aube's release bundle.
./cosign verify-blob-attestation \
  --new-bundle-format \
  --bundle packslip.sigstore.json \
  --type "$AUBE_PREDICATE" \
  --certificate-identity-regexp "$AUBE_ID_RE" \
  --certificate-oidc-issuer "$AUBE_OIDC" \
  "$tarball"

tar -xzf "$tarball" -C /usr/local/bin
chmod +x /usr/local/bin/aube /usr/local/bin/aubr /usr/local/bin/aubx
