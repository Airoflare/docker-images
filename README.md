# docker-images

Small, automatically updated Docker images by [Airoflare](https://github.com/Airoflare). Every image is multi-arch (`linux/amd64`, `linux/arm64`) and is published to both GHCR and Docker Hub.

---

## Available Images

| Image | Description | Stats
|:---|:---|:--|
| [aube](images/aube) | Node.js with the [aube](https://aube.sh) package manager, for building JS apps | ![Docker Pulls](https://shieldcn.dev/docker/pulls/airoflare/aube.svg?variant=secondary) |

---

## Tags

Each image has its own tag list in its README. The rules are the same for all images:

- **Version tags** (`1.35.0`, `v1.35.0`, `1.35.0-alpine`) point to the newest build of that version.
- **Moving tags** (`latest`, `alpine`, `debian`) point to the newest build of the newest version.
- **Dated tags** (`1.35.0-20260928`, `1.35.0-alpine-20260928`) point to one build and are not moved to later builds.

All images are rebuilt every week to get base image security fixes. The version and moving tags then point to the new build. If you need the exact same image every time, pin a dated tag or a digest.

---

## Verify an image

Every image has an SBOM and SLSA provenance attached:

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
