# static

Small runtime base images for fully static Linux binaries, such as Rust binaries built for the `*-unknown-linux-musl` target. Start with the empty `minimal` image, then choose an image with a shell, `curl`, or trusted CA certificates when your app needs those tools or data.

These are bases, not preconfigured application images: copy in your binary and set its `ENTRYPOINT` in your Dockerfile. Every variant runs as UID and GID `55555`. The base does not assume a binary name, port, health check, or writable data directory.

---

## Images

| Registry | Image |
|---|---|
| GHCR | `ghcr.io/airoflare/static` |
| Docker Hub | `docker.io/airoflare/static` |

---

## Variants & tags

All images are multi-arch (`linux/amd64`, `linux/arm64`). `<version>` below is the version of what the variant ships: an image-definition version for `minimal` (which has no packages, `1.0.0` initially, bumped in [`image.json`](image.json)), and the Alpine package version for the others — BusyBox for `shell`, curl for `curl`, and the CA certificate bundle for `certs`. The planner reads that package version from the pinned Alpine branch (`v3.24`), drops the Alpine `-rN` revision, and prepends `v`. `<date>` is the build date, e.g. `20260928`.

| Variant | Contents | Tags |
|---|---|---|
| **minimal** (default) | `scratch`; no files or commands | `latest`, `minimal`, `<version>`, `v<version>`, `<version>-minimal`, `v<version>-minimal`, `<version>-<date>`, `<version>-minimal-<date>` |
| **shell** | `scratch` plus statically linked BusyBox, `/bin/sh`, and its basic command applets | `shell`, `<version>-shell`, `v<version>-shell`, `<version>-shell-<date>` |
| **curl** | `scratch` plus `curl`, its runtime libraries, and CA certificates | `curl`, `<version>-curl`, `v<version>-curl`, `<version>-curl-<date>` |
| **certs** | `scratch` plus the CA certificate bundle | `certs`, `<version>-certs`, `v<version>-certs`, `<version>-certs-<date>` |

Images are rebuilt every week, so all tags except the `-<date>` tags move to the newest build (the version tags too, since the Alpine `-rN` revision is not part of the tag). Pin a `-<date>` tag (or a digest) if you need the exact same image every time. See [tags](../../README.md#tags).

For the exact versions in a given tag, see the [GHCR package page](https://github.com/Airoflare/docker-images/pkgs/container/static) or the corresponding Dockerfile. The `shell`, `curl`, and `certs` variants use Alpine only as a build stage; each final image is scratch-based. `shell` contains the static BusyBox binary and its applet links (a compact set of common commands, not a full GNU userland); BusyBox is licensed under GPL-2.0-only — see Alpine's [busybox-static package](https://pkgs.alpinelinux.org/package/v3.24/main/x86_64/busybox-static) and the [BusyBox source](https://busybox.net/downloads/). `curl` contains curl, the shared libraries it needs, and CA certificates, but no shell, with `SSL_CERT_FILE` pointing at the CA bundle. `certs` contains only the CA bundle beyond the empty base.

---

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

---

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

---

## Local build

From the repository root:

```bash
docker build -f images/static/minimal.Dockerfile --build-arg STATIC_VERSION=v1.0.0 -t static:minimal images/static
docker build -f images/static/shell.Dockerfile --build-arg STATIC_VERSION=v1.0.0 -t static:shell images/static
docker build -f images/static/curl.Dockerfile --build-arg STATIC_VERSION=v1.0.0 -t static:curl images/static
docker build -f images/static/certs.Dockerfile --build-arg STATIC_VERSION=v1.0.0 -t static:certs images/static
```
