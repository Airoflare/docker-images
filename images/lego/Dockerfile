# lego (ACME client) on a minimal scratch base.
#
# lego ships as a fully static Go binary, so it needs no libc or OpenSSL - only
# TLS trust roots to reach the ACME server and the DNS provider API. This image
# is the official static binary plus the CA bundle on scratch. The Alpine
# package metadata (/etc/alpine-release, /lib/apk/db/installed) is kept so image
# scanners can see the ca-certificates package; the Go binary itself is scanned
# directly. No shell, no package manager.
ARG LEGO_VERSION

FROM alpine:3.24 AS download
ARG LEGO_VERSION
ARG TARGETARCH
RUN apk add --no-cache curl
COPY fetch-lego.sh /usr/local/bin/fetch-lego.sh
RUN sh /usr/local/bin/fetch-lego.sh

# CA bundle assembled from Alpine here - not pulled from another image. The empty
# /data directory (mode 0700) is the working and storage directory.
FROM alpine:3.24 AS certs
RUN mkdir -p /rootfs/etc/apk && \
    cp /etc/apk/repositories /rootfs/etc/apk/repositories && \
    cp -a /etc/apk/keys /rootfs/etc/apk/keys && \
    apk --root /rootfs --initdb --no-cache add ca-certificates-bundle && \
    test -s /rootfs/etc/ssl/certs/ca-certificates.crt && \
    mkdir -p /datafs/data && chmod 0700 /datafs/data

FROM scratch AS final

ARG LEGO_VERSION

LABEL org.opencontainers.image.title="lego" \
      org.opencontainers.image.description="The lego ACME client on a scratch base with CA certificates" \
      org.opencontainers.image.version="${LEGO_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.url="https://github.com/go-acme/lego" \
      org.opencontainers.image.licenses="MIT"

COPY --from=certs /rootfs/etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=certs /etc/alpine-release /etc/alpine-release
COPY --from=certs /rootfs/lib/apk/db/installed /lib/apk/db/installed
COPY --from=certs --chown=55555:55555 /datafs/ /
COPY --from=download /usr/local/bin/lego /usr/local/bin/lego
COPY --from=download /usr/local/share/licenses/lego/LICENSE /usr/local/share/licenses/lego/LICENSE

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    HOME=/data
USER 55555:55555
WORKDIR /data
ENTRYPOINT ["lego"]
CMD ["--version"]
