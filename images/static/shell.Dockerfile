# Install Alpine's statically linked BusyBox into a fresh rootfs, then ship it on
# scratch with its applet links. The Alpine package metadata (/etc/alpine-release,
# /etc/os-release, /lib/apk/db/installed) is kept so image scanners can see that
# BusyBox is present; no Alpine runtime, package manager, or apk config ships.
FROM alpine:3.24 AS busybox
RUN mkdir -p /rootfs/etc/apk && \
    cp /etc/apk/repositories /rootfs/etc/apk/repositories && \
    cp -a /etc/apk/keys /rootfs/etc/apk/keys && \
    apk --root /rootfs --initdb --no-cache add alpine-release busybox-static && \
    mv /rootfs/bin/busybox.static /rootfs/bin/busybox && \
    for applet in $(/rootfs/bin/busybox --list); do ln -sf busybox "/rootfs/bin/$applet"; done && \
    rm -rf /rootfs/etc/apk /rootfs/var/cache/apk /rootfs/lib/apk/cache \
           /rootfs/lib/apk/db/scripts.tar /rootfs/lib/apk/db/triggers

FROM scratch AS final

ARG STATIC_VERSION

LABEL org.opencontainers.image.title="static" \
      org.opencontainers.image.description="Scratch runtime base for static binaries with a BusyBox shell and basic commands" \
      org.opencontainers.image.version="${STATIC_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.licenses="MIT"

COPY --from=busybox /rootfs/ /
WORKDIR /app
USER 55555:55555
CMD ["/bin/sh"]
