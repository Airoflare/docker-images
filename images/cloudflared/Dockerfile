# Cloudflare Tunnel (cloudflared) on a minimal scratch base.
#
# cloudflared ships as a fully static Go binary, so it needs no libc or OpenSSL -
# only TLS trust roots. This image is the official static binary plus the CA
# bundle on scratch. The Alpine package metadata (/etc/alpine-release,
# /lib/apk/db/installed) is kept so image scanners can see the ca-certificates
# package; the Go binary itself is scanned directly. No shell, no package manager.
ARG CLOUDFLARED_VERSION

FROM alpine:3.24 AS download
ARG CLOUDFLARED_VERSION
ARG TARGETARCH
RUN apk add --no-cache curl jq
COPY fetch-cloudflared.sh /usr/local/bin/fetch-cloudflared.sh
# github_token (when passed) only authenticates the checksum API call; it is a
# BuildKit secret, so it never lands in a layer.
RUN --mount=type=secret,id=github_token sh /usr/local/bin/fetch-cloudflared.sh

# CA bundle assembled from Alpine here - not pulled from another image.
FROM alpine:3.24 AS certs
RUN mkdir -p /rootfs/etc/apk && \
    cp /etc/apk/repositories /rootfs/etc/apk/repositories && \
    cp -a /etc/apk/keys /rootfs/etc/apk/keys && \
    apk --root /rootfs --initdb --no-cache add ca-certificates-bundle && \
    test -s /rootfs/etc/ssl/certs/ca-certificates.crt

FROM scratch AS final

ARG CLOUDFLARED_VERSION

LABEL org.opencontainers.image.title="cloudflared" \
      org.opencontainers.image.description="Cloudflare Tunnel (cloudflared) on a scratch base with CA certificates" \
      org.opencontainers.image.version="${CLOUDFLARED_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.url="https://github.com/cloudflare/cloudflared" \
      org.opencontainers.image.licenses="Apache-2.0"

COPY --from=certs /rootfs/etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=certs /etc/alpine-release /etc/alpine-release
COPY --from=certs /rootfs/lib/apk/db/installed /lib/apk/db/installed
COPY --from=download /usr/local/bin/cloudflared /usr/local/bin/cloudflared

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
USER 55555:55555
ENTRYPOINT ["cloudflared", "--no-autoupdate"]
CMD ["version"]
