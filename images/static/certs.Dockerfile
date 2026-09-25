# Add the standard CA bundle to scratch, plus the Alpine package metadata
# (/etc/alpine-release for OS detection and /lib/apk/db/installed) so image
# scanners can see the ca-certificates packages. No package manager, shell, or
# other Alpine files ship - only the bundle and that metadata.
FROM alpine:3.24 AS certificates
RUN mkdir -p /rootfs/etc/apk && \
    cp /etc/apk/repositories /rootfs/etc/apk/repositories && \
    cp -a /etc/apk/keys /rootfs/etc/apk/keys && \
    apk --root /rootfs --initdb --no-cache add ca-certificates-bundle && \
    test -s /rootfs/etc/ssl/certs/ca-certificates.crt

FROM scratch AS final

ARG STATIC_VERSION

LABEL org.opencontainers.image.title="static" \
      org.opencontainers.image.description="Empty runtime base for static binaries with CA certificates" \
      org.opencontainers.image.version="${STATIC_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.licenses="MIT"

COPY --from=certificates /rootfs/etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
# /etc/alpine-release (from the base layer) lets scanners detect the OS; the apk
# db lists the ca-certificates package that ships the bundle above.
COPY --from=certificates /etc/alpine-release /etc/alpine-release
COPY --from=certificates /rootfs/lib/apk/db/installed /lib/apk/db/installed
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
WORKDIR /app
USER 55555:55555
