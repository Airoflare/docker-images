# Use Alpine only to obtain its statically linked BusyBox package. The final
# image contains BusyBox and its applet links, with no Alpine runtime files.
FROM alpine:3.24 AS busybox
RUN apk add --no-cache busybox-static && \
    mkdir -p /rootfs/bin && \
    cp /bin/busybox.static /rootfs/bin/busybox && \
    cd /rootfs/bin && \
    for applet in $(./busybox --list); do ln -s busybox "$applet"; done

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
