# docker-images

Small, automatically updated Docker images by [Airoflare](https://github.com/Airoflare). Every image is multi-arch (`linux/amd64`, `linux/arm64`) and is published to both GHCR and Docker Hub.

---

## Available Images

| Image | Description | Stats
|:---|:---|:--|
| [aube](images/aube) | Node.js with the [aube](https://aube.sh) package manager, for building JS apps | ![Docker Pulls](https://img.shields.io/docker/pulls/airoflare/aube?style=flat&logo=docker&logoColor=fafafa&labelColor=27272a&color=27272a) |
| [static](images/static) | Runtime base images for static binaries, with optional shell, curl, and CA certificates | ![Docker Pulls](https://img.shields.io/docker/pulls/airoflare/static?style=flat&logo=docker&logoColor=fafafa&labelColor=27272a&color=27272a) |
| [cloudflared](images/cloudflared) | [Cloudflare Tunnel](https://github.com/cloudflare/cloudflared) on a scratch base, with an optional BusyBox debug shell | ![Docker Pulls](https://img.shields.io/docker/pulls/airoflare/cloudflared?style=flat&logo=docker&logoColor=fafafa&labelColor=27272a&color=27272a) |
| [sqlite](images/sqlite) | The [SQLite](https://sqlite.org) CLI on a scratch base with a BusyBox shell — run it to drop straight into the SQLite prompt | ![Docker Pulls](https://img.shields.io/docker/pulls/airoflare/sqlite?style=flat&logo=docker&logoColor=fafafa&labelColor=27272a&color=27272a) |
| [minio](images/minio) | The [MinIO](https://github.com/minio/minio) object storage server, built from the last open-source release after MinIO removed its images | ![Docker Pulls](https://img.shields.io/docker/pulls/airoflare/minio?style=flat&logo=docker&logoColor=fafafa&labelColor=27272a&color=27272a) |
| [mc](images/mc) | The open-source [MinIO Client](https://github.com/minio/mc) (`mc`), built from the last open-source release | ![Docker Pulls](https://img.shields.io/docker/pulls/airoflare/mc?style=flat&logo=docker&logoColor=fafafa&labelColor=27272a&color=27272a) |
| [castlemock](images/castlemock) | [Castle Mock](https://github.com/castlemock/castlemock) REST/SOAP service mocking, built from the last open-source release before its images are deleted | ![Docker Pulls](https://img.shields.io/docker/pulls/airoflare/castlemock?style=flat&logo=docker&logoColor=fafafa&labelColor=27272a&color=27272a) |

---

## Tags

Each image has its own tag list in its README. The rules are the same for all images:

- **Version tags** (`1.35.0`, `v1.35.0`, `1.35.0-alpine`) point to the newest build of that version.
- **Moving tags** (`latest`, `alpine`, `debian`) point to the newest build of the newest version.
- **Dated tags** (`1.35.0-20260928`, `1.35.0-alpine-20260928`) point to one build and are not moved to later builds.

All images are rebuilt every week to get base image security fixes. The version and moving tags then point to the new build. If you need the exact same image every time, pin a dated tag or a digest.

---

## Verify an image

Every image is **keyless-signed** with [cosign](https://docs.sigstore.dev/) and has an SBOM and SLSA provenance attached.

Verify the signature (works for the GHCR or Docker Hub copy — swap the registry). The identity is the GitHub Actions workflow that built it, so no public key is needed:

```bash
cosign verify \
  --certificate-identity-regexp '^https://github\.com/Airoflare/docker-images/\.github/workflows/build\.yml@refs/heads/master$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/airoflare/aube:latest
```

Inspect the SBOM and provenance:

```bash
docker buildx imagetools inspect ghcr.io/airoflare/aube:latest --format '{{ json .SBOM }}'
docker buildx imagetools inspect ghcr.io/airoflare/aube:latest --format '{{ json .Provenance }}'
```

---

## How the builds work

One workflow, [`build.yml`](.github/workflows/build.yml), builds all images:

| Trigger | What it builds |
|---|---|
| Every hour | Images whose newest upstream version is not published yet |
| Every Monday 04:00 UTC | All images, without cache |
| Push to `master` | Images whose `images/<name>/` folder changed |
| Manual run | See the inputs below |

Manual run inputs:

- `image` — build only this image (folder name). Empty = all images.
- `version` — build this upstream version instead of the newest one (needs `image`).
- `force` — rebuild even if the version is already published.
- `skip_moving_tags` — do not move `latest` and the variant tags (use it for old versions).

Each arch is built natively on its own runner and pushed by digest. The publish job then joins the digests into one multi-arch image and adds the tags on GHCR and Docker Hub.

[Renovate](https://docs.renovatebot.com/) opens PRs on weekends for new Node versions, base images and GitHub Actions ([`renovate.json`](renovate.json)). Merging a PR rebuilds the images it changed.

A second workflow, [`security.yml`](.github/workflows/security.yml), runs [Trivy](https://trivy.dev) once a week (after the rebuild) and writes a vulnerability count table into each image README. See the **Vulnerabilities** table in an image README, for example [aube](images/aube#vulnerabilities).

---

## Add an image

1. Make a folder `images/<name>/`. The folder name is the image name.
2. Add one Dockerfile per variant: `<variant>.Dockerfile`, or a single `Dockerfile` for the variant `default`.
3. Add `image.json`:

```jsonc
{
  "description": "One line about the image",
  "homepage": "https://example.com",
  "license": "MIT",
  // where the version comes from:
  //   { "type": "github-release", "repo": "owner/repo" }  - newest GitHub release
  //   { "type": "static", "version": "1.2.3" }            - you change it by hand
  "upstream": { "type": "github-release", "repo": "owner/repo" },
  "version_arg": "VERSION",           // build arg that gets the version (default: VERSION)
  "variants": ["alpine", "debian"],   // or ["default"]
  "default_variant": "alpine",        // gets latest and the bare version tags (default: first variant)
  "archs": ["amd64", "arm64"]         // optional (default: amd64 and arm64)
}
```

4. Push to `master`. The workflow builds the new image.
5. On the first run, the new GHCR package is private. Make it public in its package settings.
