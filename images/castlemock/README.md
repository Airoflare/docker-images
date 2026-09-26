# castlemock

[Castle Mock](https://github.com/castlemock/castlemock) — a web application for **mocking REST and SOAP services** — built from its **last open-source release (v1.68)** and run on a maintained [Eclipse Temurin](https://adoptium.net/) JRE.

Castle Mock's source is archived, and its official Docker Hub images are scheduled for deletion — after which no official images remain, despite the image having over a million pulls. This image keeps a working, multi-arch, signed Castle Mock available by compiling v1.68 from a preserved fork ([`Airoflare/castlemock-preserve`](https://github.com/Airoflare/castlemock-preserve)) into its executable Spring Boot jar, so it does not depend on Castle Mock's registries or repos staying up.

> [!WARNING]
> **Castle Mock is archived and frozen at v1.68 — it is no longer developed.** Only the **JRE and JDK toolchain are refreshed** on each weekly rebuild — so the app picks up **Java runtime/JVM security fixes** (where most CVEs land for a Java service), but **not** fixes to Castle Mock's frozen Java dependencies (Spring, Tomcat, etc.) or its own application code. The Castle Mock version and features stay pinned at v1.68. Intended as a compatible replacement for deployments that previously used the final `castlemock/castlemock` release — not a source of new functionality.

---

## Images

| Registry | Image |
|---|---|
| GHCR | `ghcr.io/airoflare/castlemock` |
| Docker Hub | `docker.io/airoflare/castlemock` |

---

## Tags

All images are multi-arch (`linux/amd64`, `linux/arm64`). `<version>` is the pinned Castle Mock release (`1.68` / `v1.68`), and `<date>` is the build date.

| Tag | Points to |
|---|---|
| `latest` | the newest build of the pinned release |
| `1.68`, `v1.68` | the newest build of that Castle Mock release |
| `1.68-<date>` | one specific build, never moved |

The Castle Mock version never changes, but weekly rebuilds recompile it with the current JDK and refresh the JRE base, then move `latest` and the version tags. Pin a `-<date>` tag (or a digest) for a byte-stable image. See [tags](../../README.md#tags).

---

## Vulnerabilities

<!-- TRIVY:START -->
| Tag | Arch | Critical | High | Medium | Low | Unknown |
|---|---|---|---|---|---|---|
| `latest` | amd64 | 8 | 26 | 37 | 12 | 0 |
| `latest` | arm64 | 8 | 26 | 37 | 12 | 0 |

_Scanned 2026-09-26 with Trivy 0.74.0. OS and language package CVEs, fixed and unfixed. Counts change as new advisories are published; a weekly rebuild pulls in base-image fixes._
<!-- TRIVY:END -->

Trivy scans the JRE base (Alpine packages) and the Castle Mock jar's bundled Java libraries. Because Castle Mock is frozen, findings in those Java dependencies can only be resolved by upstream, not by a rebuild — a JDK/JRE bump only fixes Java-runtime CVEs.

---

## Usage

Run it and open the web UI at **`http://localhost:8080/castlemock`** (default login **`admin`** / **`admin`** — change it after first login):

```bash
docker run -d --name castlemock -p 8080:8080 ghcr.io/airoflare/castlemock
```

Persist your mocks across restarts by mounting the data directory:

```bash
docker run -d --name castlemock -p 8080:8080 \
  -v castlemock-data:/castlemock/.castlemock \
  ghcr.io/airoflare/castlemock
```

In Compose:

```yaml
services:
  castlemock:
    image: ghcr.io/airoflare/castlemock
    ports: ["8080:8080"]
    volumes: ["castlemock-data:/castlemock/.castlemock"]
    restart: unless-stopped
volumes:
  castlemock-data:
```

The app runs as UID/GID `55555`, stores its data under `/castlemock/.castlemock`, and listens on port `8080`. If you bind-mount a host directory for the data, make sure it is writable by UID `55555`. Tune the JVM with `JAVA_TOOL_OPTIONS` (e.g. `-e JAVA_TOOL_OPTIONS=-Xmx512m`).

---

## Source & license

Castle Mock is licensed **Apache-2.0**; this image packages an unmodified build of it. The source is built from [`Airoflare/castlemock-preserve`](https://github.com/Airoflare/castlemock-preserve) at the commit tagged `v1.68`, via the project's own `deploy-tomcat-jar` (embedded-Tomcat executable jar).

---

## Local build

From the repository root:

```bash
docker build -f images/castlemock/Dockerfile --build-arg CASTLEMOCK_VERSION=v1.68 -t castlemock:latest images/castlemock
docker run --rm -p 8080:8080 castlemock:latest
```
