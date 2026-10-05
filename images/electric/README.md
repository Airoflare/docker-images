# electric

The [Electric](https://github.com/electric-sql/electric) sync service — a Postgres sync engine that syncs subsets of your Postgres data into local apps over HTTP — built from the **last release** in a preserved fork.

ElectricSQL removed its public Docker images (`electricsql/electric`), which broke self-hosted setups that pulled them. This image keeps a working, multi-arch, signed Electric server available by building the sync service from a preserved fork ([`Airoflare/electricsql-preserve`](https://github.com/Airoflare/electricsql-preserve)) with the same steps as the upstream Dockerfile, so it does not depend on ElectricSQL's registries staying up.

> [!WARNING]
> **The Electric version is pinned** to the last release in the fork (`1.8.1`). Weekly rebuilds refresh the base images only; they do not pick up new Electric releases or fixes to Electric's own code and dependencies. Intended as a compatible replacement for deployments that used the `electricsql/electric` image.

---

## Images

| Registry | Image |
|---|---|
| GHCR | `ghcr.io/airoflare/electric` |
| Docker Hub | `docker.io/airoflare/electric` |

---

## Tags

All images are multi-arch (`linux/amd64`, `linux/arm64`). `<version>` is the pinned Electric release (`1.8.1`), and `<date>` is the build date.

| Tag | Points to |
|---|---|
| `latest` | the newest build of the pinned release |
| `<version>` | the newest build of that Electric release |
| `<version>-<date>` | one specific build, never moved |

Weekly rebuilds refresh the base images, then move `latest` and `<version>`. Pin a `-<date>` tag (or a digest) for a byte-stable image. See [tags](../../README.md#tags).

---

## Vulnerabilities

<!-- TRIVY:START -->
| Tag | Arch | Critical | High | Medium | Low | Unknown |
|---|---|---|---|---|---|---|
| `latest` | amd64 | 4 | 72 | 166 | 150 | 4 |
| `latest` | arm64 | 4 | 72 | 166 | 150 | 4 |

_Scanned 2026-10-05 with Trivy 0.74.0. OS and language package CVEs, fixed and unfixed. Counts change as new advisories are published; a weekly rebuild pulls in base-image fixes._
<!-- TRIVY:END -->

---

## Usage

Electric needs a Postgres database with logical replication (`wal_level=logical`). Point `DATABASE_URL` at it:

```bash
docker run -d --name electric \
  -p 3000:3000 \
  -e DATABASE_URL='postgresql://postgres:password@db:5432/postgres?sslmode=disable' \
  -e ELECTRIC_SECRET=change-me-please \
  -v electric-data:/app/persistent \
  ghcr.io/airoflare/electric
```

The HTTP API is on `:3000` (`/v1/shape`, `/v1/health`). Set `ELECTRIC_SECRET` to protect the API, or `ELECTRIC_INSECURE=true` for local development only.

In Compose:

```yaml
services:
  postgres:
    image: postgres:17-alpine
    command: ["postgres", "-c", "wal_level=logical"]
    environment:
      POSTGRES_PASSWORD: password
    volumes: ["pg-data:/var/lib/postgresql/data"]
  electric:
    image: ghcr.io/airoflare/electric
    ports: ["3000:3000"]
    environment:
      DATABASE_URL: postgresql://postgres:password@postgres:5432/postgres?sslmode=disable
      ELECTRIC_SECRET: change-me-please
    volumes: ["electric-data:/app/persistent"]
    depends_on: [postgres]
    restart: unless-stopped
volumes:
  pg-data:
  electric-data:
```

Electric keeps its shape logs and state under `/app/persistent` (`ELECTRIC_STORAGE_DIR`). The process runs as root, like the upstream image, so named volumes and bind-mounted host directories work without permission changes. All other settings are the same environment variables as upstream; see the [Electric configuration docs](https://electric-sql.com/docs/api/config).

---

## Local build

From the repository root:

```bash
docker build -f images/electric/Dockerfile --build-arg ELECTRIC_VERSION=1.8.1 -t electric:latest images/electric
curl -s localhost:3000/v1/health   # after starting it with DATABASE_URL set
```
