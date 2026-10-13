# SQLite CLI (sqlite3) on a scratch base.
#
# `docker run -it` drops straight into the interactive SQLite prompt. The sqlite3
# binary is the statically linked, hardened build from peakimages/sqlite
# (https://github.com/peakimages/sqlite) - a colleague-maintained image that
# compiles the sqlite.org-recommended options with FTS3/4/5, R*Tree, geopoly and
# the math functions built in. Being a static PIE, it needs no runtime libraries.
# A statically linked BusyBox provides /bin/sh and basic commands for file work.
# The Alpine package metadata (/etc/alpine-release, /lib/apk/db/installed) is kept
# so image scanners see the busybox package; no package manager ships.

# Source of the sqlite3 binary. This pinned tag is the single source of truth for
# the SQLite version: Renovate's docker manager keeps it current, and
# scripts/helpers/sqlite.sh reads the version from this line. The tag format is
# <sqlite-version>-v<image-version> (e.g. 3.53.4-v0.1.0).
FROM peakimages/sqlite:3.54.0-v0.1.0 AS sqlite

FROM alpine:3.24 AS rootfs
RUN mkdir -p /rootfs/etc/apk && \
    cp /etc/apk/repositories /rootfs/etc/apk/repositories && \
    cp -a /etc/apk/keys /rootfs/etc/apk/keys && \
    apk --root /rootfs --initdb --no-cache add alpine-release busybox-static && \
    mv /rootfs/bin/busybox.static /rootfs/bin/busybox && \
    for applet in $(/rootfs/bin/busybox --list); do ln -sf busybox "/rootfs/bin/$applet"; done && \
    mkdir -p /rootfs/data && chown 55555:55555 /rootfs/data && \
    rm -rf /rootfs/etc/apk /rootfs/var/cache/apk /rootfs/lib/apk/cache \
           /rootfs/lib/apk/db/scripts.tar /rootfs/lib/apk/db/triggers

COPY --from=sqlite /usr/local/bin/sqlite3 /rootfs/usr/local/bin/sqlite3
RUN chroot /rootfs /usr/local/bin/sqlite3 --version

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
