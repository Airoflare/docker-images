# Add the standard CA bundle to scratch without shipping a package manager,
# shell, or other Alpine files.
FROM alpine:3.24 AS certificates
RUN apk add --no-cache ca-certificates

FROM scratch AS final

ARG STATIC_VERSION

LABEL org.opencontainers.image.title="static" \
      org.opencontainers.image.description="Empty runtime base for static binaries with CA certificates" \
      org.opencontainers.image.version="${STATIC_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.licenses="MIT"

COPY --from=certificates /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
WORKDIR /app
USER 55555:55555
