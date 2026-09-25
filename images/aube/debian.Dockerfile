# Aube (https://aube.sh) + Node.js on Debian (trixie-slim)
# glibc variant for JS apps whose native dependencies don't play well with musl.
#
# Same layout as the Alpine variant: bare base image + node binary + a single
# aube binary (aubr/aubx are byte-identical multi-call copies, so symlinked).
# The aube musl binary is fully static, so it runs on glibc systems too.

ARG NODE_VERSION=24.18.0

FROM node:${NODE_VERSION}-trixie-slim AS node

# Download stage - fetch prebuilt static musl binaries from GitHub releases
FROM alpine:3.22 AS downloader

ARG AUBE_VERSION
ARG TARGETARCH

RUN apk add --no-cache curl

RUN case "${TARGETARCH}" in \
        amd64) ARCH="x86_64" ;; \
        arm64) ARCH="aarch64" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/aubepkg/aube/releases/download/${AUBE_VERSION}/aube-${AUBE_VERSION}-${ARCH}-unknown-linux-musl.tar.gz" \
        | tar -xz -C /usr/local/bin && \
    chmod +x /usr/local/bin/aube /usr/local/bin/aubr /usr/local/bin/aubx

# Runtime stage
FROM debian:trixie-slim

ARG AUBE_VERSION
ARG NODE_VERSION

LABEL org.opencontainers.image.title="aube" \
      org.opencontainers.image.description="Node.js ${NODE_VERSION} (Debian slim) with the aube package manager, for building JS apps" \
      org.opencontainers.image.version="${AUBE_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.url="https://aube.sh" \
      org.opencontainers.image.licenses="MIT"

# ca-certificates for TLS (registry downloads)
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=downloader /usr/local/bin/aube /usr/local/bin/aube

# aubr and aubx are identical multi-call binaries - symlink instead of copying 3x
RUN ln -s aube /usr/local/bin/aubr && \
    ln -s aube /usr/local/bin/aubx

# Verify the binaries work
RUN node --version && aube --version && aubr --version && aubx --version

WORKDIR /app

CMD ["aube"]
