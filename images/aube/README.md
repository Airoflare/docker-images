# aube

Lightweight Docker images for [aube](https://aube.sh) — a fast, security-first Node.js package manager — bundled with Node.js.

Built for one job: **building/installing JS apps in Docker and CI**. There is no npm, npx, corepack or yarn in these images; aube replaces them. It reads and writes `package-lock.json`, `yarn.lock` and `pnpm-lock.yaml` in place, so it drops into existing projects without lockfile migration.

## Images

| Registry | Image |
|---|---|
| GHCR | `ghcr.io/airoflare/aube` |
| Docker Hub | `docker.io/airoflare/aube` |

## Variants & tags

All images are multi-arch (`linux/amd64`, `linux/arm64`). `<version>` below is the aube release, e.g. `1.35.0`. `<date>` is the build date, e.g. `20260928`.

| Variant | Base | Tags |
|---|---|---|
| **alpine** (default) | Alpine 3.22 (musl) | `latest`, `alpine`, `<version>`, `v<version>`, `<version>-alpine`, `v<version>-alpine`, `<version>-<date>`, `<version>-alpine-<date>` |
| **debian** | Debian trixie-slim (glibc) | `debian`, `<version>-debian`, `v<version>-debian`, `<version>-debian-<date>` |

Images are rebuilt every week, so all tags except the `-<date>` tags move to the newest build. Pin a `-<date>` tag (or a digest) if you need the exact same image every time. See [tags](../../README.md#tags).

Use the **debian** variant if your app has native dependencies that don't play well with musl (glibc-only prebuilt binaries, sharp/canvas edge cases, etc.). Otherwise the alpine variant is smaller.

## What's inside

- Node.js **24.18.0** (`NODE_VERSION` in the Dockerfiles, kept up to date by Renovate) copied onto a bare base image — only `ca-certificates` and node's runtime libs are added
- `aube` static musl binary from [official GitHub releases](https://github.com/aubepkg/aube/releases), with `aubr` (script runner) and `aubx` (like npx) as symlinks — they are identical multi-call binaries, and the same static binary works in both variants
- No npm / npx / corepack / yarn

## Vulnerabilities

<!-- TRIVY:START -->
| Tag | Arch | Critical | High | Medium | Low | Unknown |
|---|---|---|---|---|---|---|
| `alpine` | amd64 | 0 | 0 | 0 | 0 | 0 |
| `alpine` | arm64 | 0 | 0 | 0 | 0 | 0 |
| `debian` | amd64 | 0 | 43 | 53 | 56 | 2 |
| `debian` | arm64 | 0 | 43 | 53 | 56 | 2 |

_Scanned 2026-09-25 with Trivy 0.74.0. OS and language package CVEs, fixed and unfixed. Counts change as new advisories are published; a weekly rebuild pulls in base-image fixes._
<!-- TRIVY:END -->

## Usage

As a build stage in your app's Dockerfile:

```dockerfile
FROM ghcr.io/airoflare/aube:latest AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN aube install
COPY . .
RUN aubr build
```

Or directly:

```bash
docker run --rm -v "$PWD:/app" ghcr.io/airoflare/aube:latest aube install
```

## Local build

From this folder:

```bash
docker build -f alpine.Dockerfile --build-arg AUBE_VERSION=v1.35.0 -t aube:alpine .
docker build -f debian.Dockerfile --build-arg AUBE_VERSION=v1.35.0 -t aube:debian .
docker run --rm aube:alpine aube --version
```
