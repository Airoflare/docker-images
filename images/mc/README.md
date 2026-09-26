# mc

The open-source [MinIO Client](https://github.com/minio/mc) (`mc`) — the `mc alias`, `mc cp`, `mc mirror`, `mc admin` CLI for S3-compatible object storage — built from the **last open-source release** and shipped on a minimal `scratch` base with a BusyBox shell and CA certificates.

MinIO archived `github.com/minio/mc`, stopped publishing its Docker images, and removed the old ones from Docker Hub, which broke a lot of tooling that depended on `minio/mc`. This image exists to keep a working, multi-arch, signed `mc` available. It compiles the last open-source `mc` release from a preserved fork ([`Airoflare/mino-mc-preserve`](https://github.com/Airoflare/mino-mc-preserve)) so it does not depend on MinIO's registries or repos staying up.

> [!WARNING]
> **This open-source `mc` is frozen — it is no longer developed.** MinIO stopped releasing the open-source `mc`; the current AIStor Client is distributed under MinIO's proprietary software license. Here, only the **Go toolchain and base image are refreshed** on each weekly rebuild — so the binary picks up fixes in the Go runtime/standard library it actually uses, plus CA and BusyBox updates, but **not** fixes to MinIO's frozen dependencies or `mc`'s own code. The `mc` version and features stay pinned at the last open-source release. Intended as a compatible replacement for deployments that previously used the final open-source `minio/mc` release — not a source of new `mc` functionality. The current AIStor Client (`quay.io/minio/aistor/mc`) is not repackaged here, as its proprietary license does not permit redistribution.

---

## Images

| Registry | Image |
|---|---|
| GHCR | `ghcr.io/airoflare/mc` |
| Docker Hub | `docker.io/airoflare/mc` |

---

## Tags

All images are multi-arch (`linux/amd64`, `linux/arm64`). `<version>` is the pinned `mc` release (`RELEASE.2025-08-13T08-35-41Z`), and `<date>` is the build date, e.g. `20260928`.

| Tag | Points to |
|---|---|
| `latest` | the newest build of the pinned release |
| `<version>` | the newest build of that `mc` release |
| `<version>-<date>` | one specific build, never moved |

The `mc` version never changes, but weekly rebuilds recompile it with the current Go toolchain and refresh the base, then move `latest` and `<version>` to that build. Pin a `-<date>` tag (or a digest) for a byte-stable image. See [tags](../../README.md#tags).

---

## Vulnerabilities

<!-- TRIVY:START -->
| Tag | Arch | Critical | High | Medium | Low | Unknown |
|---|---|---|---|---|---|---|
| `latest` | amd64 | 1 | 22 | 16 | 0 | 2 |
| `latest` | arm64 | 1 | 22 | 16 | 0 | 2 |

_Scanned 2026-09-26 with Trivy 0.74.0. OS and language package CVEs, fixed and unfixed. Counts change as new advisories are published; a weekly rebuild pulls in base-image fixes._
<!-- TRIVY:END -->

Trivy scans both the `mc` Go binary (for CVEs in its Go dependencies) and the Alpine `ca-certificates` package. Because `mc` is frozen, dependency findings can only be resolved by a Go-toolchain bump on rebuild, not by an `mc` update.

---

## Usage

`mc` is the entrypoint, so pass its subcommands directly. Configuration and aliases are written under `/home/mc/.mc` (the container's writable `HOME`); mount it to persist them, or use `MC_HOST_<alias>` environment variables to avoid writing config at all.

Mirror a bucket, configuring the alias inline via env:

```bash
docker run --rm \
  -e MC_HOST_myminio="https://ACCESS_KEY:SECRET_KEY@minio.example.com" \
  -v "$PWD/backup:/data" \
  ghcr.io/airoflare/mc mirror myminio/mybucket /data
```

Persist aliases across runs by mounting the config directory, then use them:

```bash
docker run --rm -v mc-config:/home/mc/.mc ghcr.io/airoflare/mc \
  alias set myminio https://minio.example.com ACCESS_KEY SECRET_KEY
docker run --rm -v mc-config:/home/mc/.mc ghcr.io/airoflare/mc ls myminio
```

Chain several commands with the bundled shell:

```bash
docker run --rm --entrypoint /bin/sh ghcr.io/airoflare/mc -c \
  'mc alias set m https://minio.example.com KEY SECRET && mc mb m/newbucket && mc ls m'
```

The process runs as UID/GID `55555`, and `/home/mc` is owned by that ID so `mc` can write its config. `mc` needs the CA bundle (already included, with `SSL_CERT_FILE` set) to reach HTTPS endpoints.

---

## Source & license

`mc` is licensed **AGPL-3.0-or-later** (© MinIO, Inc.); this image only packages an unmodified build of it. The source is built from [`Airoflare/mino-mc-preserve`](https://github.com/Airoflare/mino-mc-preserve) at the commit tagged `RELEASE.2025-08-13T08-35-41Z`, with the standard `mc` version ldflags — run `mc --version` in the image to see the exact commit.

---

## Local build

From the repository root:

```bash
docker build -f images/mc/Dockerfile --build-arg MC_VERSION=RELEASE.2025-08-13T08-35-41Z -t mc:latest images/mc
docker run --rm mc:latest --version
```
