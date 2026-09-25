# cloudflared on a scratch base with a BusyBox debug shell.
#
# The same static cloudflared binary and CA bundle as the default image, plus a
# statically linked BusyBox (/bin/sh and net tools like wget, nslookup, ping,
# netstat, ip) so you can `docker exec` into a running tunnel and debug DNS or
# connectivity. Still scratch: no package manager, no Alpine runtime.
ARG CLOUDFLARED_VERSION

FROM alpine:3.24 AS download
ARG CLOUDFLARED_VERSION
ARG TARGETARCH
RUN apk add --no-cache curl
COPY fetch-cloudflared.sh /usr/local/bin/fetch-cloudflared.sh
RUN sh /usr/local/bin/fetch-cloudflared.sh

# BusyBox + CA bundle assembled from Alpine here - not pulled from another image.
FROM alpine:3.24 AS rootfs
RUN mkdir -p /rootfs/etc/apk && \
    cp /etc/apk/repositories /rootfs/etc/apk/repositories && \
    cp -a /etc/apk/keys /rootfs/etc/apk/keys && \
    apk --root /rootfs --initdb --no-cache add alpine-release busybox-static ca-certificates-bundle && \
    mv /rootfs/bin/busybox.static /rootfs/bin/busybox && \
    for applet in $(/rootfs/bin/busybox --list); do ln -sf busybox "/rootfs/bin/$applet"; done && \
    test -s /rootfs/etc/ssl/certs/ca-certificates.crt && \
    rm -rf /rootfs/etc/apk /rootfs/var/cache/apk /rootfs/lib/apk/cache \
           /rootfs/lib/apk/db/scripts.tar /rootfs/lib/apk/db/triggers

FROM scratch AS final

ARG CLOUDFLARED_VERSION

LABEL org.opencontainers.image.title="cloudflared" \
      org.opencontainers.image.description="Cloudflare Tunnel (cloudflared) on a scratch base with a BusyBox debug shell and CA certificates" \
      org.opencontainers.image.version="${CLOUDFLARED_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.url="https://github.com/cloudflare/cloudflared" \
      org.opencontainers.image.licenses="Apache-2.0"

COPY --from=rootfs /rootfs/ /
COPY --from=download /usr/local/bin/cloudflared /usr/local/bin/cloudflared

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
USER 55555:55555
ENTRYPOINT ["cloudflared", "--no-autoupdate"]
CMD ["version"]
