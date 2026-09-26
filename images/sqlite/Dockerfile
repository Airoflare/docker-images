# SQLite CLI (sqlite3) on a scratch base.
#
# `docker run -it` drops straight into the interactive SQLite prompt. A
# statically linked BusyBox provides /bin/sh and basic commands for file work.
# The Alpine package metadata (/etc/alpine-release, /lib/apk/db/installed) is kept
# so image scanners see the sqlite packages; no package manager ships.
FROM alpine:3.24 AS rootfs
RUN mkdir -p /rootfs/etc/apk && \
    cp /etc/apk/repositories /rootfs/etc/apk/repositories && \
    cp -a /etc/apk/keys /rootfs/etc/apk/keys && \
    apk --root /rootfs --initdb --no-cache add alpine-release busybox-static sqlite && \
    mv /rootfs/bin/busybox.static /rootfs/bin/busybox && \
    for applet in $(/rootfs/bin/busybox --list); do ln -sf busybox "/rootfs/bin/$applet"; done && \
    mkdir -p /rootfs/data && chown 55555:55555 /rootfs/data && \
    chroot /rootfs /usr/bin/sqlite3 --version && \
    rm -rf /rootfs/etc/apk /rootfs/var/cache/apk /rootfs/lib/apk/cache \
           /rootfs/lib/apk/db/scripts.tar /rootfs/lib/apk/db/triggers

FROM scratch AS final

ARG SQLITE_VERSION

LABEL org.opencontainers.image.title="sqlite" \
      org.opencontainers.image.description="SQLite CLI (sqlite3) on a scratch base with a BusyBox shell" \
      org.opencontainers.image.version="${SQLITE_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.url="https://sqlite.org" \
      org.opencontainers.image.licenses="blessing"

COPY --from=rootfs /rootfs/ /
WORKDIR /data
USER 55555:55555
ENTRYPOINT ["sqlite3"]
