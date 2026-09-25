# static

Small runtime base images for fully static Linux binaries, such as Rust binaries built for the `*-unknown-linux-musl` target. Start with the empty `minimal` image, then choose an image with a shell, `curl`, or trusted CA certificates when your app needs those tools or data.

These are bases, not preconfigured application images: copy in your binary and set its `ENTRYPOINT` in your Dockerfile. Every variant runs as UID and GID `55555`. The base does not assume a binary name, port, health check, or writable data directory.

## Images

| Registry | Image |
|---|---|
| GHCR | `ghcr.io/airoflare/static` |
| Docker Hub | `docker.io/airoflare/static` |

## Variants and tags

All images support `linux/amd64` and `linux/arm64`. Each variant is versioned by what it actually ships, and the version tags below use example versions — see the [GHCR package page](https://github.com/Airoflare/docker-images/pkgs/container/static) for the current numbers:

- **minimal** carries no packages, so it uses a manually maintained image-definition version (`1.0.0` initially, bumped in [`image.json`](image.json)). As the default variant it also owns the bare version, `latest`, and `minimal` tags.
- **shell**, **curl**, and **certs** are versioned by their Alpine package — BusyBox for `shell`, curl for `curl`, and the CA certificate bundle for `certs`. The build planner reads that version from the pinned Alpine branch (`v3.24`), drops the Alpine `-rN` package revision, and prepends `v`. When Alpine ships a new upstream version of the package, the hourly build picks it up automatically and publishes new version tags.

Weekly rebuilds refresh the Alpine-based variants for base-image security fixes and move the non-dated tags (including the current version tags, since the `-rN` revision is not part of the tag); dated tags stay fixed. Example tags below use BusyBox `1.37.0`, curl `8.22.0`, and CA bundle `20260909`:

| Variant | Contents | Tags |
|---|---|---|
| **minimal** (default) | `scratch`; no files or commands | `latest`, `minimal`, `1.0.0`, `v1.0.0`, `1.0.0-minimal`, `v1.0.0-minimal`, dated equivalents |
| **shell** | `scratch` plus statically linked BusyBox, `/bin/sh`, and its basic command applets | `shell`, `1.37.0-shell`, `v1.37.0-shell`, dated equivalent |
| **curl** | `scratch` plus `curl`, its runtime libraries, and CA certificates | `curl`, `8.22.0-curl`, `v8.22.0-curl`, dated equivalent |
| **certs** | `scratch` plus the CA certificate bundle | `certs`, `20260909-certs`, `v20260909-certs`, dated equivalent |

For the exact Alpine version in a tag, see the corresponding Dockerfile. The shell variant uses Alpine only as a build stage; its final image is scratch-based and contains the static BusyBox binary and applet links. BusyBox is licensed under GPL-2.0-only; see Alpine's [busybox-static package](https://pkgs.alpinelinux.org/package/v3.24/main/x86_64/busybox-static) and the [BusyBox source](https://busybox.net/downloads/). BusyBox applets are a compact set of common commands, not a full GNU userland. The curl variant also uses Alpine only as a build stage; its scratch final image contains curl, the shared libraries curl needs, and CA certificates, but no shell. `SSL_CERT_FILE` points curl to the CA bundle. The certs variant stays scratch-based and contains only the CA bundle beyond the empty base.

## Vulnerabilities

<!-- TRIVY:START -->
| Tag | Arch | Critical | High | Medium | Low | Unknown |
|---|---|---|---|---|---|---|
| `minimal` | amd64 | 0 | 0 | 0 | 0 | 0 |
| `minimal` | arm64 | 0 | 0 | 0 | 0 | 0 |
| `shell` | amd64 | 0 | 0 | 0 | 0 | 0 |
| `shell` | arm64 | 0 | 0 | 0 | 0 | 0 |
| `curl` | amd64 | 0 | 0 | 0 | 0 | 0 |
| `curl` | arm64 | 0 | 0 | 0 | 0 | 0 |
| `certs` | amd64 | 0 | 0 | 0 | 0 | 0 |
| `certs` | arm64 | 0 | 0 | 0 | 0 | 0 |

_Scanned 2026-09-25 with Trivy 0.74.0. OS and language package CVEs, fixed and unfixed. Counts change as new advisories are published; a weekly rebuild pulls in base-image fixes._
<!-- TRIVY:END -->

## Usage

Use the minimal image for a self-contained static executable:

```dockerfile
FROM ghcr.io/airoflare/static:minimal
COPY --chmod=0555 target/x86_64-unknown-linux-musl/release/myapp /app/myapp
ENTRYPOINT ["/app/myapp"]
```

For HTTPS requests from the binary, use `certs`:

```dockerfile
FROM ghcr.io/airoflare/static:certs
COPY --chmod=0555 target/x86_64-unknown-linux-musl/release/myapp /app/myapp
ENTRYPOINT ["/app/myapp"]
```

For a health check that calls an HTTP endpoint, use `curl` and add the check to your application image. The exec form works in the scratch image without a shell:

```dockerfile
FROM ghcr.io/airoflare/static:curl
COPY --chmod=0555 target/x86_64-unknown-linux-musl/release/myapp /app/myapp
ENTRYPOINT ["/app/myapp"]
HEALTHCHECK --interval=30s --timeout=3s CMD ["curl", "--fail", "--silent", "http://127.0.0.1:8080/health"]
```

Choose `shell` when you need to run shell commands in the container. For example, `docker run --rm -it --entrypoint /bin/sh your-app:tag` opens a shell in an image based on this variant.

The binary's target architecture must match the image platform. `scratch` contains no shell, certificates, timezone data, or user database; add only what the application needs. The process runs as UID/GID `55555` in every variant. If your app needs writable paths, create or mount them with permissions for that ID.

## Local build

From the repository root:

```bash
docker build -f images/static/minimal.Dockerfile --build-arg STATIC_VERSION=1.0.0 -t static:minimal images/static
docker build -f images/static/shell.Dockerfile --build-arg STATIC_VERSION=1.0.0 -t static:shell images/static
docker build -f images/static/curl.Dockerfile --build-arg STATIC_VERSION=1.0.0 -t static:curl images/static
docker build -f images/static/certs.Dockerfile --build-arg STATIC_VERSION=1.0.0 -t static:certs images/static
```
