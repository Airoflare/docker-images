#!/usr/bin/env bash
# Decides which images to build and writes these outputs to $GITHUB_OUTPUT:
#   builds    - one entry per image + variant + arch (build job matrix)
#   manifests - one entry per image + variant        (publish job matrix)
#   has_builds, date
#
# Triggers:
#   schedule (hourly) - build images whose upstream version is not published yet
#   schedule (weekly) - rebuild every image without cache (base image fixes)
#   push              - rebuild images whose folder changed
#   workflow_dispatch - see the inputs in build.yml
set -euo pipefail

: "${OWNER:?}" "${EVENT:?}" "${WEEKLY_CRON:?}"
force="${INPUT_FORCE:-false}"
no_cache=false
date=$(date -u +%Y%m%d)

if [ -n "${INPUT_VERSION:-}" ] && [ -z "${INPUT_IMAGE:-}" ]; then
  echo "::error::The version input needs the image input"
  exit 1
fi
if [ -n "${INPUT_IMAGE:-}" ] && [ ! -f "images/$INPUT_IMAGE/image.json" ]; then
  echo "::error::images/$INPUT_IMAGE/image.json does not exist"
  exit 1
fi

if [ "$EVENT" = "schedule" ] && [ "${SCHEDULE:-}" = "$WEEKLY_CRON" ]; then
  force=true
  no_cache=true
fi

changed=""
if [ "$EVENT" = "push" ]; then
  force=true
  if [ -n "${BEFORE:-}" ] && git cat-file -e "${BEFORE}^{commit}" 2> /dev/null; then
    changed=$(git diff --name-only "$BEFORE" HEAD -- images/ | cut -d/ -f2 | sort -u)
  else
    # first push or force push: the old commit is unknown, so rebuild everything
    changed=$(ls images)
  fi
fi

builds='[]'
manifests='[]'

for dir in images/*/; do
  name=$(basename "$dir")
  cfg="${dir}image.json"
  [ -f "$cfg" ] || continue

  if [ -n "${INPUT_IMAGE:-}" ] && [ "$name" != "$INPUT_IMAGE" ]; then continue; fi
  if [ "$EVENT" = "push" ] && ! grep -qx "$name" <<< "$changed"; then continue; fi

  # Each image owns its versioning in scripts/helpers/<image>.sh: given a variant
  # ($1) it prints that variant's version (e.g. a GitHub release tag or an Alpine
  # package version). A dispatch version overrides it, so a helper is required
  # only when no version was passed in.
  helper="scripts/helpers/$name.sh"
  if [ -z "${INPUT_VERSION:-}" ] && [ ! -x "$helper" ]; then
    echo "::error::$name: no version input and no helper at $helper"
    exit 1
  fi

  default_variant=$(jq -r '.default_variant // .variants[0]' "$cfg")
  archs=$(jq -r '(.archs // ["amd64", "arm64"]) | join(" ")' "$cfg")
  version_arg=$(jq -r '.version_arg // "VERSION"' "$cfg")

  for variant in $(jq -r '.variants[]' "$cfg"); do
    if [ -n "${INPUT_VERSION:-}" ]; then
      version="$INPUT_VERSION"
    else
      version=$("$helper" "$variant")
    fi

    if [ -z "$version" ] || [ "$version" = "null" ]; then
      echo "::error::$name $variant: could not find the version"
      exit 1
    fi

    # The default variant carries the bare version tag; a named variant carries
    # "<version>-<variant>". Probe that tag to see if this variant is published.
    if [ "$variant" = "$default_variant" ]; then
      probe="$version"
    else
      probe="$version-$variant"
    fi
    if [ "$force" != "true" ] && docker manifest inspect "ghcr.io/$OWNER/$name:$probe" > /dev/null 2>&1; then
      echo "$name $variant $version: already published, skip"
      continue
    fi
    echo "$name $variant $version: build"

    build_args="$version_arg=$version"
    if [ "$variant" = "default" ]; then
      file="images/$name/Dockerfile"
    else
      file="images/$name/$variant.Dockerfile"
    fi

    for arch in $archs; do
      runner="ubuntu-26.04"
      [ "$arch" = "arm64" ] && runner="ubuntu-26.04-arm"
      builds=$(jq -c \
        --arg image "$name" --arg version "$version" --arg variant "$variant" \
        --arg arch "$arch" --arg runner "$runner" --arg file "$file" \
        --arg build_args "$build_args" --argjson no_cache "$no_cache" \
        '. + [{image: $image, version: $version, variant: $variant, arch: $arch,
               runner: $runner, file: $file, build_args: $build_args, no_cache: $no_cache}]' \
        <<< "$builds")
    done

    manifests=$(jq -c \
      --arg image "$name" --arg version "$version" --arg variant "$variant" \
      --arg archs "$archs" --argjson is_default "$([ "$variant" = "$default_variant" ] && echo true || echo false)" \
      '. + [{image: $image, version: $version, variant: $variant, archs: $archs, is_default: $is_default}]' \
      <<< "$manifests")
  done
done

has_builds=true
[ "$builds" = "[]" ] && has_builds=false

{
  echo "builds=$builds"
  echo "manifests=$manifests"
  echo "has_builds=$has_builds"
  echo "date=$date"
} >> "$GITHUB_OUTPUT"
