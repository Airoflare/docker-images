#!/bin/sh
# Download the official lego release tarball for the target architecture and
# verify it against the SHA256 checksum file lego publishes with each release.
#
# lego ships as a fully static Go binary (CGO_ENABLED=0), so it needs no libc at
# runtime. The release has a checksums file in sha256sum format; we check our
# download against it and fail on any mismatch or a missing line. lego also has
# GitHub artifact attestations, which this script does not check.
set -eu

: "${LEGO_VERSION:?}" "${TARGETARCH:?}"

case "$TARGETARCH" in
  amd64 | arm64) ARCH="$TARGETARCH" ;;
  *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;;
esac

version="${LEGO_VERSION#v}"   # the helper prints "v5.5.2"; the file names differ below
asset="lego_v${version}_linux_${ARCH}.tar.gz"
sums="lego_${version}_checksums.txt"   # no "v" in the checksums file name
base="https://github.com/go-acme/lego/releases/download/v${version}"

mkdir -p /tmp/lego && cd /tmp/lego
curl -fsSL -o "$asset" "$base/$asset"
curl -fsSL -o "$sums" "$base/$sums"

# Exactly one "<sha256>  <asset>" line must exist, and it must match.
line=$(awk -v f="$asset" '$2 == f' "$sums")
if [ -z "$line" ] || [ "$(printf '%s\n' "$line" | wc -l)" -ne 1 ]; then
  echo "No single SHA256 checksum for ${asset} in ${sums}" >&2
  exit 1
fi
printf '%s\n' "$line" | sha256sum -c -

tar -xzf "$asset" lego LICENSE
install -m 0555 lego /usr/local/bin/lego
install -D -m 0444 LICENSE /usr/local/share/licenses/lego/LICENSE

# Sanity check: it must actually run.
/usr/local/bin/lego --version
