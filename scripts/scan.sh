#!/usr/bin/env bash
# Scans each published image variant with Trivy and writes a vulnerability
# summary table into its README, between the TRIVY:START and TRIVY:END markers.
# If a README has no markers, a "Vulnerabilities" section is added at the end.
#
# Needs: trivy, jq, python3, and a docker login to ghcr.io for private images.
set -euo pipefail

: "${OWNER:?}"
SEVERITIES="CRITICAL,HIGH,MEDIUM,LOW,UNKNOWN"
DATE="$(date -u +%Y-%m-%d)"
TRIVY_VERSION="$(trivy --version | awk 'NR==1 {print $2}')"

for cfg in images/*/image.json; do
  image="$(basename "$(dirname "$cfg")")"
  readme="images/$image/README.md"
  variants=()
  while IFS= read -r v; do variants+=("$v"); done < <(jq -r '.variants[]' "$cfg")
  # Same default as the build plan: scan every arch the image is published for.
  archs=()
  while IFS= read -r a; do archs+=("$a"); done \
    < <(jq -r '(.archs // ["amd64","arm64"])[]' "$cfg")

  rows=()
  for variant in "${variants[@]}"; do
    if [ "$variant" = "default" ]; then tag="latest"; else tag="$variant"; fi
    ref="ghcr.io/$OWNER/$image:$tag"

    # Trivy scans only the manifest's default platform (amd64), so scan each
    # arch explicitly - otherwise arm64 gets no CVE numbers.
    for arch in "${archs[@]}"; do
      echo "Scanning $ref (linux/$arch)"

      # One scan per variant+arch; keep only fixed + unfixed OS/language CVEs.
      json="$(trivy image --quiet --scanners vuln --format json \
        --platform "linux/$arch" --severity "$SEVERITIES" "$ref")"

      # Count vulnerabilities per severity from the Trivy JSON.
      read -r crit high med low unk < <(jq -r '
        [.Results[]?.Vulnerabilities[]?.Severity] as $s
        | [ "CRITICAL","HIGH","MEDIUM","LOW","UNKNOWN" ]
        | map(. as $x | ($s | map(select(. == $x)) | length))
        | @tsv' <<<"$json")

      rows+=("| \`$tag\` | $arch | $crit | $high | $med | $low | $unk |")
    done
  done

  block="$(printf '%s\n' \
    "| Tag | Arch | Critical | High | Medium | Low | Unknown |" \
    "|---|---|---|---|---|---|---|" \
    "${rows[@]}" \
    "" \
    "_Scanned $DATE with Trivy $TRIVY_VERSION. OS and language package CVEs, fixed and unfixed. Counts change as new advisories are published; a weekly rebuild pulls in base-image fixes._")"

  README_PATH="$readme" BLOCK="$block" python3 - <<'PY'
import os, pathlib
readme = pathlib.Path(os.environ["README_PATH"])
block = os.environ["BLOCK"]
START, END = "<!-- TRIVY:START -->", "<!-- TRIVY:END -->"
section = f"{START}\n{block}\n{END}"
text = readme.read_text()
if START in text and END in text:
    pre = text[: text.index(START)]
    post = text[text.index(END) + len(END):]
    text = pre + section + post
else:
    text = text.rstrip() + "\n\n## Vulnerabilities\n\n" + section + "\n"
readme.write_text(text)
print(f"Updated {readme}")
PY
done
