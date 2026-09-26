# cloudflared

[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) (`cloudflared`) packaged on a minimal `scratch` base. `cloudflared` ships as a fully static Go binary, so it needs no libc or OpenSSL at runtime — only TLS trust roots. These images are the official binary plus the CA bundle on `scratch`, with an optional BusyBox **debug** variant for when you need to shell in.

Compared with the official `cloudflare/cloudflared` image (based on `distroless/base-debian13`), these images:

- **Drop the unused glibc and OpenSSL layers.** The release binary is static, so the ~32 MB of `libc6`/`libssl3` the official image inherits from its Debian base is never loaded. We ship only the binary and CA roots.
- **Offer a `debug` variant with a shell.** The official image is distroless — there is no `/bin/sh`, so you cannot `docker exec` in to diagnose a tunnel. Our `debug` variant adds BusyBox (`sh`, `wget`, `nslookup`, `ping`, `netstat`, `ip`).
- **Are keyless-signed with an SBOM and SLSA provenance**, published to **both GHCR and Docker Hub**, and **rebuilt weekly** for CA/BusyBox security refreshes. The official image is unsigned and ships no SBOM.

> [!NOTE]
> Cloudflare publishes a **SHA256 checksum** for every release asset in the GitHub release notes, and these images **verify the downloaded binary against it at build time** — a mismatch fails the build. Unlike aube, Cloudflare does not additionally sign the binaries with sigstore (no keyless signature proving which workflow built them), so this verifies integrity against Cloudflare's published checksum but not signed provenance.

---

## Images

| Registry | Image |
|---|---|
| GHCR | `ghcr.io/airoflare/cloudflared` |
| Docker Hub | `docker.io/airoflare/cloudflared` |

---

## Variants & tags

All images are multi-arch (`linux/amd64`, `linux/arm64`). `<version>` is the upstream `cloudflared` release, e.g. `2026.9.3`. `<date>` is the build date, e.g. `20260928`.

| Variant | Contents | Tags |
|---|---|---|
| **default** | `scratch` + CA certificates + `cloudflared` | `latest`, `<version>`, `v<version>`, `<version>-<date>` |
| **debug** | the above plus a statically linked BusyBox shell and net tools | `debug`, `<version>-debug`, `v<version>-debug`, `<version>-debug-<date>` |

Images are rebuilt every week, so all tags except the `-<date>` tags move to the newest build. Pin a `-<date>` tag (or a digest) if you need the exact same image every time. See [tags](../../README.md#tags).

Both variants run as UID/GID `55555`, with `ENTRYPOINT ["cloudflared", "--no-autoupdate"]` and CA trust configured via `SSL_CERT_FILE`. The Alpine package metadata (`/etc/alpine-release`, `/lib/apk/db/installed`) is kept so image scanners see the `ca-certificates` package, and the `cloudflared` Go binary is scanned directly for known CVEs in its dependencies.

---

## Vulnerabilities

<!-- TRIVY:START -->
| Tag | Arch | Critical | High | Medium | Low | Unknown |
|---|---|---|---|---|---|---|
| `latest` | amd64 | 0 | 0 | 2 | 0 | 1 |
| `latest` | arm64 | 0 | 0 | 2 | 0 | 1 |
| `debug` | amd64 | 0 | 0 | 2 | 0 | 1 |
| `debug` | arm64 | 0 | 0 | 2 | 0 | 1 |

_Scanned 2026-09-26 with Trivy 0.74.0. OS and language package CVEs, fixed and unfixed. Counts change as new advisories are published; a weekly rebuild pulls in base-image fixes._
<!-- TRIVY:END -->

Any findings here are in `cloudflared`'s own Go dependencies (upstream code), not in the packaging. They are surfaced only because these images carry an SBOM and are scanned; the official image publishes neither.

---

## Usage

Run a named tunnel with a token (the token carries the tunnel config):

```bash
docker run --rm ghcr.io/airoflare/cloudflared:latest tunnel run --token <YOUR_TUNNEL_TOKEN>
```

In Compose:

```yaml
services:
  cloudflared:
    image: ghcr.io/airoflare/cloudflared:latest
    command: tunnel run
    environment:
      TUNNEL_TOKEN: ${TUNNEL_TOKEN}
    restart: unless-stopped
```

The entrypoint is `cloudflared --no-autoupdate`, so pass only the subcommand and its flags (`tunnel run …`, `version`, `--help`).

To debug a running tunnel, use the **debug** variant and open a shell in the container:

```bash
docker run -d --name tunnel ghcr.io/airoflare/cloudflared:debug tunnel run --token <YOUR_TUNNEL_TOKEN>
docker exec -it tunnel /bin/sh
# inside: nslookup example.com, wget -qO- https://…, netstat -tunlp, ip addr
```

---

## Local build

From the repository root (`<version>` is a `cloudflared` release such as `2026.9.3`):

```bash
docker build -f images/cloudflared/Dockerfile       --build-arg CLOUDFLARED_VERSION=v<version> -t cloudflared:latest images/cloudflared
docker build -f images/cloudflared/debug.Dockerfile --build-arg CLOUDFLARED_VERSION=v<version> -t cloudflared:debug  images/cloudflared
docker run --rm cloudflared:latest version
```
