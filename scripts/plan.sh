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

  if [ -n "${INPUT_VERSION:-}" ]; then
    version="$INPUT_VERSION"
  else
    type=$(jq -r '.upstream.type' "$cfg")
    case "$type" in
      github-release)
        repo=$(jq -r '.upstream.repo' "$cfg")
        version=$(gh api "repos/$repo/releases/latest" --jq '.tag_name')
        ;;
      static)
        version=$(jq -r '.upstream.version' "$cfg")
        ;;
      *)
        echo "::error::$name: unknown upstream type '$type'"
        exit 1
        ;;
    esac
  fi

  if [ -z "$version" ] || [ "$version" = "null" ]; then
    echo "::error::$name: could not find the version"
    exit 1
  fi

  # The default variant always gets the bare version tag, so check that tag
  if [ "$force" != "true" ] && docker manifest inspect "ghcr.io/$OWNER/$name:$version" > /dev/null 2>&1; then
    echo "$name $version: already published, skip"
    continue
  fi
  echo "$name $version: build"

  default_variant=$(jq -r '.default_variant // .variants[0]' "$cfg")
  archs=$(jq -r '(.archs // ["amd64", "arm64"]) | join(" ")' "$cfg")
  build_args="$(jq -r '.version_arg // "VERSION"' "$cfg")=$version"

  for variant in $(jq -r '.variants[]' "$cfg"); do
    if [ "$variant" = "default" ]; then
      file="images/$name/Dockerfile"
    else
      file="images/$name/$variant.Dockerfile"
    fi

    for arch in $archs; do
      runner="ubuntu-24.04"
      [ "$arch" = "arm64" ] && runner="ubuntu-24.04-arm"
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
