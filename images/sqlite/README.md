# sqlite

The [SQLite](https://sqlite.org) CLI (`sqlite3`) on a minimal `scratch` base. Run it interactively and you land **straight in the SQLite prompt** — no shell dance, no full OS image. A statically linked BusyBox is included, so you can still `docker exec` in for file work when you need it.

The image is the Alpine `sqlite` build and its runtime libraries on `scratch`, nothing else: no package manager, no application server, just the tool.

---

## Images

| Registry | Image |
|---|---|
| GHCR | `ghcr.io/airoflare/sqlite` |
| Docker Hub | `docker.io/airoflare/sqlite` |

---

## Tags

All images are multi-arch (`linux/amd64`, `linux/arm64`). `<version>` is the SQLite version, e.g. `3.53.4` — read from the pinned Alpine branch (`v3.24`), with the Alpine `-rN` package revision dropped and a `v` prepended. `<date>` is the build date, e.g. `20260928`.

| Tag | Points to |
|---|---|
| `latest` | the newest build |
| `<version>`, `v<version>` | the newest build of that SQLite version |
| `<version>-<date>` | one specific build, never moved |

Images are rebuilt every week, so all tags except the `-<date>` tags move to the newest build. Pin a `-<date>` tag (or a digest) if you need the exact same image every time. See [tags](../../README.md#tags).

---

## Vulnerabilities

<!-- TRIVY:START -->
| Tag | Arch | Critical | High | Medium | Low | Unknown |
|---|---|---|---|---|---|---|
| `latest` | amd64 | 0 | 0 | 0 | 0 | 0 |
| `latest` | arm64 | 0 | 0 | 0 | 0 | 0 |

_Scanned 2026-09-26 with Trivy 0.74.0. OS and language package CVEs, fixed and unfixed. Counts change as new advisories are published; a weekly rebuild pulls in base-image fixes._
<!-- TRIVY:END -->

---

## Usage

Jump straight into a transient in-memory database:

```bash
docker run --rm -it ghcr.io/airoflare/sqlite
# sqlite> create table t(x); insert into t values(1); select * from t;
```

Open a database file by mounting the directory that holds it into `/data` (the working directory):

```bash
docker run --rm -it -v "$PWD:/data" ghcr.io/airoflare/sqlite mydb.db
```

Run a one-off query and exit — anything after the entrypoint is passed to `sqlite3`:

```bash
docker run --rm -v "$PWD:/data" ghcr.io/airoflare/sqlite mydb.db "select count(*) from users;"
```

Need a shell (BusyBox) instead of the SQLite prompt — for example to inspect or copy files:

```bash
docker run --rm -it --entrypoint /bin/sh ghcr.io/airoflare/sqlite
```

The process runs as UID/GID `55555`, and `/data` is owned by that ID so `sqlite3` can create database files there. If you mount a host directory, make sure it is writable by UID `55555` (or mount an existing file). `scratch` carries no other tools, so add only what your workflow needs.

---

## Local build

From the repository root (`<version>` is a SQLite release such as `3.53.4`):

```bash
docker build -f images/sqlite/Dockerfile --build-arg SQLITE_VERSION=v<version> -t sqlite:latest images/sqlite
docker run --rm -it sqlite:latest
```
