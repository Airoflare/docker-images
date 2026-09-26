# MinIO Client (mc), built from source from the last open-source release.
#
# MinIO archived github.com/minio/mc and removed its Docker images; the current
# mc on quay.io/minio/aistor/mc is the closed-source AIStor build. This image
# compiles the last open-source mc release from a preserved fork
# (github.com/Airoflare/mino-mc-preserve) and ships the static binary on scratch
# with a BusyBox shell and CA certificates.
ARG MC_VERSION

# Build stage - compile mc with the same version ldflags mc's own build sets.
FROM golang:1.24-alpine AS builder

ARG MC_VERSION
ARG TARGETARCH
# Commit of the last open-source release (RELEASE.2025-08-13T08-35-41Z). Keep it
# in step with MC_VERSION in scripts/helpers/mc.sh when moving to another.
ARG MC_COMMIT=7394ce0dd2a80935aded936b09fa12cbb3cb8096
ARG MC_REPO=https://github.com/Airoflare/mino-mc-preserve.git

ENV CGO_ENABLED=0 GOOS=linux

RUN apk add --no-cache git
WORKDIR /src
RUN git init -q && git remote add origin "$MC_REPO" && \
    git fetch -q --depth 1 origin "$MC_COMMIT" && git checkout -q FETCH_HEAD

# -tags kqueue and the -X version vars mirror mc's Makefile/gen-ldflags output.
RUN set -eu; \
    commit=$(git rev-parse HEAD); short=$(git rev-parse --short=12 HEAD); \
    vtime=$(echo "$MC_VERSION" | sed 's/RELEASE\.//' | sed 's/T/ /' | sed 's/-/:/3' | sed 's/-/:/3' | sed 's/ /T/'); \
    GOARCH="$TARGETARCH" go build -trimpath -tags kqueue \
      -ldflags "-s -w \
        -X github.com/minio/mc/cmd.Version=${vtime} \
        -X github.com/minio/mc/cmd.ReleaseTag=${MC_VERSION} \
        -X github.com/minio/mc/cmd.CommitID=${commit} \
        -X github.com/minio/mc/cmd.ShortCommitID=${short} \
        -X github.com/minio/mc/cmd.CopyrightYear=2025" \
      -o /out/mc . ; \
    /out/mc --version

# BusyBox shell + CA certificates assembled from Alpine (not another image). The
# Alpine package metadata is kept so scanners see the ca-certificates package.
FROM alpine:3.24 AS rootfs
RUN mkdir -p /rootfs/etc/apk && \
    cp /etc/apk/repositories /rootfs/etc/apk/repositories && \
    cp -a /etc/apk/keys /rootfs/etc/apk/keys && \
    apk --root /rootfs --initdb --no-cache add alpine-release busybox-static ca-certificates-bundle && \
    mv /rootfs/bin/busybox.static /rootfs/bin/busybox && \
    for applet in $(/rootfs/bin/busybox --list); do ln -sf busybox "/rootfs/bin/$applet"; done && \
    test -s /rootfs/etc/ssl/certs/ca-certificates.crt && \
    mkdir -p /rootfs/home/mc && chown 55555:55555 /rootfs/home/mc && \
    rm -rf /rootfs/etc/apk /rootfs/var/cache/apk /rootfs/lib/apk/cache \
           /rootfs/lib/apk/db/scripts.tar /rootfs/lib/apk/db/triggers

FROM scratch AS final

ARG MC_VERSION

LABEL org.opencontainers.image.title="mc" \
      org.opencontainers.image.description="MinIO Client (mc), last open-source release, on a scratch base with a BusyBox shell" \
      org.opencontainers.image.version="${MC_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.url="https://github.com/minio/mc" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later"

COPY --from=rootfs /rootfs/ /
COPY --from=builder /out/mc /usr/bin/mc

ENV HOME=/home/mc \
    MC_CONFIG_DIR=/home/mc/.mc \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
WORKDIR /home/mc
USER 55555:55555
ENTRYPOINT ["mc"]
