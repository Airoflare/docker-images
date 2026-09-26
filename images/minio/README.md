# minio

The [MinIO](https://github.com/minio/minio) object storage server (S3-compatible), built from the **last open-source release** and shipped on a minimal `scratch` base with a BusyBox shell and CA certificates.

MinIO archived `github.com/minio/minio`, removed its Docker images, and pivoted to the closed-source AIStor product — breaking a lot of self-hosted setups that depended on the `minio/minio` image. This image keeps a working, multi-arch, signed MinIO server available by compiling the last open-source release from a preserved fork ([`Airoflare/minio-preserve`](https://github.com/Airoflare/minio-preserve)), so it does not depend on MinIO's registries or repos staying up.

> [!WARNING]
> **This open-source MinIO server is frozen — it is no longer developed.** MinIO stopped releasing the open-source server; ongoing development is in the closed-source AIStor product. Only the **Go toolchain and base image are refreshed** on each weekly rebuild (so the binary keeps getting Go-runtime and CA/BusyBox security fixes) — the MinIO version, features, and upstream fixes stay pinned at the last open-source release. Use it as a stable drop-in for the removed `minio/minio` image, not as a source of new MinIO functionality.

---

## Images

| Registry | Image |
|---|---|
| GHCR | `ghcr.io/airoflare/minio` |
| Docker Hub | `docker.io/airoflare/minio` |

---

## Tags

All images are multi-arch (`linux/amd64`, `linux/arm64`). `<version>` is the pinned MinIO release (`RELEASE.2025-10-15T17-29-55Z`), and `<date>` is the build date.

| Tag | Points to |
|---|---|
| `latest` | the newest build of the pinned release |
| `<version>` | the newest build of that MinIO release |
| `<version>-<date>` | one specific build, never moved |

The MinIO version never changes, but weekly rebuilds recompile it with the current Go toolchain and refresh the base, then move `latest` and `<version>`. Pin a `-<date>` tag (or a digest) for a byte-stable image. See [tags](../../README.md#tags).

---

## Vulnerabilities

<!-- TRIVY:START -->
| Tag | Arch | Critical | High | Medium | Low | Unknown |
|---|---|---|---|---|---|---|
| `latest` | amd64 | 6 | 58 | 28 | 3 | 2 |
| `latest` | arm64 | 6 | 58 | 28 | 3 | 2 |

_Scanned 2026-09-26 with Trivy 0.74.0. OS and language package CVEs, fixed and unfixed. Counts change as new advisories are published; a weekly rebuild pulls in base-image fixes._
<!-- TRIVY:END -->

Trivy scans both the `minio` Go binary (for CVEs in its Go dependencies) and the Alpine `ca-certificates` package. Because MinIO is frozen, dependency findings can only be resolved by a Go-toolchain bump on rebuild, not by a MinIO update.

---

## Usage

The default command starts a single-node server on `/data` with the console on port 9001. Set the root credentials and mount a data volume:

```bash
docker run -d --name minio \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=change-me-please \
  -v minio-data:/data \
  ghcr.io/airoflare/minio
```

The S3 API is on `:9000` and the web console on `:9001`. Override the command for a custom layout (for example distributed mode):

```bash
docker run ... ghcr.io/airoflare/minio server /data --address :9000 --console-address :9001
```

In Compose:

```yaml
services:
  minio:
    image: ghcr.io/airoflare/minio
    ports: ["9000:9000", "9001:9001"]
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: change-me-please
    volumes: ["minio-data:/data"]
    restart: unless-stopped
volumes:
  minio-data:
```

The process runs as UID/GID `55555`, and `/data` is owned by that ID. If you bind-mount a host directory instead of a named volume, make sure it is writable by UID `55555`. Pair it with the [`mc`](../mc) client image to manage buckets.

---

## Local build

From the repository root:

```bash
docker build -f images/minio/Dockerfile --build-arg MINIO_VERSION=RELEASE.2025-10-15T17-29-55Z -t minio:latest images/minio
docker run --rm minio:latest --version
```
