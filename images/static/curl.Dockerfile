# Assemble curl, its shared-library dependencies, and CA certificates into a
# fresh rootfs with Alpine's package manager, then ship that filesystem on
# scratch. The Alpine package metadata (/etc/alpine-release, /etc/os-release,
# /lib/apk/db/installed) is kept so image scanners can see the packages that are
# present; no shell, package manager, or apk config ships.
FROM alpine:3.24 AS curl-rootfs
# alpine-release provides /etc/alpine-release and /etc/os-release (needed for OS
# detection). ca-certificates-bundle ships the prebuilt /etc/ssl/certs/ca-
# certificates.crt as a plain file, so the bundle exists even though `apk --root`
# runs no post-install trigger to regenerate it.
RUN mkdir -p /rootfs/etc/apk && \
    cp /etc/apk/repositories /rootfs/etc/apk/repositories && \
    cp -a /etc/apk/keys /rootfs/etc/apk/keys && \
    apk --root /rootfs --initdb --no-cache add alpine-release curl ca-certificates-bundle && \
    test -s /rootfs/etc/ssl/certs/ca-certificates.crt && \
    rm -rf /rootfs/etc/apk /rootfs/var/cache/apk /rootfs/lib/apk/cache \
           /rootfs/lib/apk/db/scripts.tar /rootfs/lib/apk/db/triggers

FROM scratch AS final

ARG STATIC_VERSION

LABEL org.opencontainers.image.title="static" \
      org.opencontainers.image.description="Scratch runtime base for static binaries with curl and CA certificates" \
      org.opencontainers.image.version="${STATIC_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.licenses="MIT"

COPY --from=curl-rootfs /rootfs/ /
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
WORKDIR /app
USER 55555:55555
