# Assemble curl, its shared-library dependencies, and CA certificates using
# Alpine's package manager. Only that runtime filesystem enters the final image.
FROM alpine:3.24 AS curl-rootfs
# ca-certificates-bundle is named explicitly: it ships the prebuilt
# /etc/ssl/certs/ca-certificates.crt as a plain file, so the bundle exists even
# though `apk --root` runs no post-install trigger to regenerate it.
RUN apk add --no-cache findutils && \
    mkdir -p /rootfs/etc/apk && \
    cp /etc/apk/repositories /rootfs/etc/apk/repositories && \
    cp -a /etc/apk/keys /rootfs/etc/apk/keys && \
    apk --root /rootfs --initdb --no-cache add busybox curl ca-certificates ca-certificates-bundle && \
    test -s /rootfs/etc/ssl/certs/ca-certificates.crt && \
    find /rootfs -type l -lname '*busybox' -delete && \
    rm -rf /rootfs/bin /rootfs/sbin && \
    rm -rf /rootfs/etc/apk /rootfs/lib/apk /rootfs/var/cache/apk

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
