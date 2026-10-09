# lego

[lego](https://github.com/go-acme/lego), the Let's Encrypt / ACME client, packaged on a minimal `scratch` base. `lego` ships as a fully static Go binary, so it needs no libc or OpenSSL at runtime — only TLS trust roots to reach the ACME server and your DNS provider's API. These images are the official binary plus the CA bundle on `scratch`, with an optional BusyBox **debug** variant for when you need to shell in.

Compared with the official `goacme/lego` image (based on `alpine:3`, with `git` and `tzdata`), these images:

- **Drop the Alpine userland.** The release binary is static (`CGO_ENABLED=0`), so it needs no libc, shell, or package manager. We ship only the binary and CA roots: about 21 MB compressed on amd64 and 19 MB on arm64, versus 31.9 MB and 30.3 MB. See [what is left out](#what-is-left-out) for the few optional features this affects.
- **Run as a non-root user.** The official image runs as root. These images run as UID/GID `55555`, so the certificates and keys lego writes (mode `0600`) are owned by that user, not root.
- **Work with a read-only root filesystem.** `lego` runs from `/data` (the working directory, `HOME`, and the place to mount storage) and needs nothing else writable — not even `/tmp`.
- **Are keyless-signed with an SBOM and SLSA provenance**, published to **both GHCR and Docker Hub**, and **rebuilt weekly** for CA/BusyBox security refreshes.

### What is left out

The official image also installs `git`, `tzdata`, and a shell. lego does not need them to get or renew certificates — the HTTP-01, TLS-ALPN-01, and DNS-01 challenges work without them, including DNS providers that only call an HTTP API, such as Cloudflare. A few optional features do use them:

| Left out | Used by | If you need it |
|---|---|---|
| shell | `hooks` and the `exec` DNS provider, when the command is a shell script | Use the **debug** variant (BusyBox `sh`), or point the command at a static binary you mount in. |
| `git` | Nothing in lego itself. Only a hook script that you write might call it. | Use the official image. |
| `tzdata` | The `wedos` DNS provider (it falls back to a built-in CET calculation without it), and local times in logs when `TZ` is set | Nothing to do: log times are in UTC. |

> [!NOTE]
> lego publishes a **SHA256 checksums file** with every release, and these images **verify the downloaded tarball against it at build time** — a mismatch or a missing checksum fails the build. lego also publishes GitHub artifact attestations for its tarballs, which this build does not check, so this verifies integrity against lego's published checksum but not signed provenance.

---

## Images

| Registry | Image |
|---|---|
| GHCR | `ghcr.io/airoflare/lego` |
| Docker Hub | `docker.io/airoflare/lego` |

---

## Variants & tags

All images are multi-arch (`linux/amd64`, `linux/arm64`). `<version>` is the upstream `lego` release, e.g. `5.5.2`. `<date>` is the build date, e.g. `20260928`.

| Variant | Contents | Tags |
|---|---|---|
| **default** | `scratch` + CA certificates + `lego` | `latest`, `<version>`, `v<version>`, `<version>-<date>` |
| **debug** | the above plus a statically linked BusyBox shell and net tools | `debug`, `<version>-debug`, `v<version>-debug`, `<version>-debug-<date>` |

Images are rebuilt every week, so all tags except the `-<date>` tags move to the newest build. Pin a `-<date>` tag (or a digest) if you need the exact same image every time. See [tags](../../README.md#tags).

Both variants run as UID/GID `55555` in `/data` (also `HOME`), with `ENTRYPOINT ["lego"]`, a default `CMD ["--version"]`, and CA trust configured via `SSL_CERT_FILE`. No `CF_*`, `CLOUDFLARE_*`, or `LEGO_*` variables are set in the image. The upstream MIT license is at `/usr/local/share/licenses/lego/LICENSE`. The Alpine package metadata (`/etc/alpine-release`, `/lib/apk/db/installed`) is kept so image scanners see the `ca-certificates` package, and the `lego` Go binary is scanned directly for known CVEs in its dependencies.

---

## Vulnerabilities

<!-- TRIVY:START -->
| Tag | Arch | Critical | High | Medium | Low | Unknown |
|---|---|---|---|---|---|---|
| `latest` | amd64 | 0 | 2 | 3 | 0 | 14 |
| `latest` | arm64 | 0 | 2 | 3 | 0 | 14 |
| `debug` | amd64 | 0 | 2 | 3 | 0 | 14 |
| `debug` | arm64 | 0 | 2 | 3 | 0 | 14 |

_Scanned 2026-10-09 with Trivy 0.74.0. OS and language package CVEs, fixed and unfixed. Counts change as new advisories are published; a weekly rebuild pulls in base-image fixes._
<!-- TRIVY:END -->

Any findings here are in `lego`'s own Go dependencies (upstream code), not in the packaging.

---

## Usage

The image is meant to run as a short-lived container: start it on a schedule (for example once a day) with a [config file](https://go-acme.github.io/lego/references/ref-file/), let it get or renew the certificates, and act on the exit code (`0` = success). Running it again when nothing is due takes a second or two.

A config for wildcard certificates with the Cloudflare DNS-01 challenge. Each `challenges` entry can read its token from its own env file, so one run can serve several Cloudflare accounts:

```yaml
# lego.yml
storage: /data
log:
  format: text          # the default "colored" adds ANSI codes to the logs
accounts:
  main:
    email: you@example.com
    acceptsTermsOfService: true
challenges:
  cf-a:
    dns: { provider: cloudflare, envFile: /secrets/cf-a.env }   # CF_DNS_API_TOKEN=...
certificates:
  example.com:
    challenge: cf-a
    account: main
    domains: [example.com, '*.example.com']
    renew: { disableRandomSleep: true }
```

Run it with a read-only root filesystem and no capabilities:

```bash
docker run --rm --read-only --cap-drop ALL --security-opt no-new-privileges \
  -v /srv/lego/data:/data \
  -v /srv/lego/lego.yml:/config/lego.yml:ro \
  -v /srv/lego/secrets:/secrets:ro \
  ghcr.io/airoflare/lego:latest --config /config/lego.yml
```

Certificates are written to `/data/certificates/<name>.crt` (leaf + chain), `.key`, `.issuer.crt`, `.pem`, and `.json`, all mode `0600`.

Things to know:

- **Ownership.** A bind mount hides the image's `/data`, so the host directory must be owned by `55555:55555`, and `lego.yml` and the env files must be readable by that user. Any process that reads the keys (for example your web server) must run as the same UID.
- **Random sleep.** When stdout is not a TTY, lego sleeps 0 to 8 minutes per certificate before a real renewal. Set `renew: { disableRandomSleep: true }` per certificate, or allow a long timeout.
- **Env precedence.** A `CLOUDFLARE_*` variable passed to the container wins over `CF_*` in an env file. Do not set either on the container when you use `envFile`.
- **Backup file.** After each run, lego writes the effective config to `/data/.lego.bck.yaml`. It holds the `envFile` paths, not the tokens.
- **Network.** lego needs outbound HTTPS to the ACME server and the DNS provider API. It does not listen on any port.

To debug permissions or connectivity, use the **debug** variant and open a shell:

```bash
docker run --rm -it --entrypoint /bin/sh -v /srv/lego/data:/data ghcr.io/airoflare/lego:debug
# inside: id, ls -ln /data, nslookup api.cloudflare.com, wget -qO- https://…
```

---

## Local build

From the repository root (`<version>` is a `lego` release such as `5.5.2`):

```bash
docker build -f images/lego/Dockerfile       --build-arg LEGO_VERSION=v<version> -t lego:latest images/lego
docker build -f images/lego/debug.Dockerfile --build-arg LEGO_VERSION=v<version> -t lego:debug  images/lego
docker run --rm lego:latest --version
```
