# lego (ACME client) on a scratch base with a BusyBox debug shell.
#
# The same static lego binary and CA bundle as the default image, plus a
# statically linked BusyBox (/bin/sh and net tools like wget, nslookup, ping)
# so you can open a shell and debug DNS, file permissions or connectivity to
# the ACME server. Still scratch: no package manager, no Alpine runtime.
ARG LEGO_VERSION

FROM alpine:3.24 AS download
ARG LEGO_VERSION
ARG TARGETARCH
RUN apk add --no-cache curl
COPY fetch-lego.sh /usr/local/bin/fetch-lego.sh
RUN sh /usr/local/bin/fetch-lego.sh

# BusyBox + CA bundle assembled from Alpine here - not pulled from another image.
# The empty /data directory (mode 0700) is the working and storage directory.
FROM alpine:3.24 AS rootfs
RUN mkdir -p /rootfs/etc/apk && \
    cp /etc/apk/repositories /rootfs/etc/apk/repositories && \
    cp -a /etc/apk/keys /rootfs/etc/apk/keys && \
    apk --root /rootfs --initdb --no-cache add alpine-release busybox-static ca-certificates-bundle && \
    mv /rootfs/bin/busybox.static /rootfs/bin/busybox && \
    for applet in $(/rootfs/bin/busybox --list); do ln -sf busybox "/rootfs/bin/$applet"; done && \
    test -s /rootfs/etc/ssl/certs/ca-certificates.crt && \
    rm -rf /rootfs/etc/apk /rootfs/var/cache/apk /rootfs/lib/apk/cache \
           /rootfs/lib/apk/db/scripts.tar /rootfs/lib/apk/db/triggers && \
    mkdir -p /datafs/data && chmod 0700 /datafs/data

FROM scratch AS final

ARG LEGO_VERSION

LABEL org.opencontainers.image.title="lego" \
      org.opencontainers.image.description="The lego ACME client on a scratch base with a BusyBox debug shell and CA certificates" \
      org.opencontainers.image.version="${LEGO_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.url="https://github.com/go-acme/lego" \
      org.opencontainers.image.licenses="MIT"

COPY --from=rootfs /rootfs/ /
COPY --from=rootfs --chown=55555:55555 /datafs/ /
COPY --from=download /usr/local/bin/lego /usr/local/bin/lego
COPY --from=download /usr/local/share/licenses/lego/LICENSE /usr/local/share/licenses/lego/LICENSE

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    HOME=/data
USER 55555:55555
WORKDIR /data
ENTRYPOINT ["lego"]
CMD ["--version"]
