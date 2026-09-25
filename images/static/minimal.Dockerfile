# Empty runtime base for fully static binaries. Copy your binary into the
# consuming image and set its ENTRYPOINT there.
FROM scratch

ARG STATIC_VERSION

LABEL org.opencontainers.image.title="static" \
      org.opencontainers.image.description="Empty runtime base for static binaries" \
      org.opencontainers.image.version="${STATIC_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.licenses="MIT"

WORKDIR /app
USER 55555:55555
