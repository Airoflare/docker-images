# MinIO object storage server, built from source from the last open-source release.
#
# MinIO archived github.com/minio/minio and removed its Docker images, pivoting to
# the closed-source AIStor product. This image compiles the last open-source minio
# release from a preserved fork (github.com/Airoflare/minio-preserve) and ships
# the static binary on scratch with a BusyBox shell and CA certificates.
ARG MINIO_VERSION

# Build stage - compile minio with the same version ldflags minio's own build sets.
FROM golang:1.27-alpine AS builder

ARG MINIO_VERSION
ARG TARGETARCH
# Commit of the last open-source release (RELEASE.2025-10-15T17-29-55Z). Keep it
# in step with MINIO_VERSION in scripts/helpers/minio.sh when moving to another.
ARG MINIO_COMMIT=9e49d5e7a648f00e26f2246f4dc28e6b07f8c84a
ARG MINIO_REPO=https://github.com/Airoflare/minio-preserve.git

ENV CGO_ENABLED=0 GOOS=linux

RUN apk add --no-cache git
WORKDIR /src
RUN git init -q && git remote add origin "$MINIO_REPO" && \
    git fetch -q --depth 1 origin "$MINIO_COMMIT" && git checkout -q FETCH_HEAD

# -tags kqueue and the -X version vars mirror minio's Makefile/gen-ldflags output.
RUN set -eu; \
    commit=$(git rev-parse HEAD); short=$(git rev-parse --short=12 HEAD); \
    vtime=$(echo "$MINIO_VERSION" | sed 's/RELEASE\.//' | sed 's/T/ /' | sed 's/-/:/3' | sed 's/-/:/3' | sed 's/ /T/'); \
    GOARCH="$TARGETARCH" go build -trimpath -tags kqueue \
      -ldflags "-s -w \
        -X github.com/minio/minio/cmd.Version=${vtime} \
        -X github.com/minio/minio/cmd.ReleaseTag=${MINIO_VERSION} \
        -X github.com/minio/minio/cmd.CommitID=${commit} \
        -X github.com/minio/minio/cmd.ShortCommitID=${short} \
        -X github.com/minio/minio/cmd.CopyrightYear=2025" \
      -o /out/minio . ; \
    /out/minio --version

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
    mkdir -p /rootfs/data && chown 55555:55555 /rootfs/data && \
    rm -rf /rootfs/etc/apk /rootfs/var/cache/apk /rootfs/lib/apk/cache \
           /rootfs/lib/apk/db/scripts.tar /rootfs/lib/apk/db/triggers

FROM scratch AS final

ARG MINIO_VERSION

LABEL org.opencontainers.image.title="minio" \
      org.opencontainers.image.description="MinIO object storage server, last open-source release, on a scratch base with a BusyBox shell" \
      org.opencontainers.image.version="${MINIO_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.url="https://github.com/minio/minio" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later"

COPY --from=rootfs /rootfs/ /
COPY --from=builder /out/minio /usr/bin/minio

ENV HOME=/data \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
EXPOSE 9000 9001
VOLUME ["/data"]
WORKDIR /data
USER 55555:55555
ENTRYPOINT ["minio"]
CMD ["server", "/data", "--console-address", ":9001"]
