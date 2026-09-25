# Aube (https://aube.sh) + Node.js on Alpine
# Lightweight image intended for building/installing JS apps with aube.
#
# The final stage starts from bare Alpine and copies in only the node binary
# and a single aube binary (aubr/aubx are byte-identical multi-call copies,
# so they are symlinked). This avoids shipping npm/corepack/yarn and the
# whiteout overhead of deleting them from the node base image.

ARG NODE_VERSION=24.18.0

FROM node:${NODE_VERSION}-alpine AS node

# Download stage - fetch prebuilt static musl binaries from GitHub releases
FROM alpine:3.24 AS downloader

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
FROM alpine:3.24

ARG AUBE_VERSION
ARG NODE_VERSION

LABEL org.opencontainers.image.title="aube" \
      org.opencontainers.image.description="Node.js ${NODE_VERSION} (Alpine) with the aube package manager, for building JS apps" \
      org.opencontainers.image.version="${AUBE_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.url="https://aube.sh" \
      org.opencontainers.image.licenses="MIT"

# node needs libstdc++/libgcc; ca-certificates for TLS (registry downloads)
RUN apk add --no-cache libstdc++ libgcc ca-certificates

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=downloader /usr/local/bin/aube /usr/local/bin/aube

# aubr and aubx are identical multi-call binaries - symlink instead of copying 3x
RUN ln -s aube /usr/local/bin/aubr && \
    ln -s aube /usr/local/bin/aubx

# Verify the binaries work
RUN node --version && aube --version && aubr --version && aubx --version

WORKDIR /app

CMD ["aube"]
