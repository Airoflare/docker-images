#!/usr/bin/env bash
# Joins the per-arch digests of one image variant into a multi-arch image and
# applies its tags on GHCR and Docker Hub.
#
# Tags for a named variant (for example aube "debian", version v1.2.3):
#   v1.2.3-debian, 1.2.3-debian, 1.2.3-debian-<date>, debian
# The default variant also gets:
#   v1.2.3, 1.2.3, 1.2.3-<date>, latest
# A variant named "default" gets only the second list.
# SKIP_MOVING_TAGS=true skips "latest" and the bare variant tag.
set -euo pipefail

: "${OWNER:?}" "${IMAGE:?}" "${VERSION:?}" "${VARIANT:?}" "${IS_DEFAULT:?}" "${ARCHS:?}" "${DATE:?}" "${DIGESTS_DIR:?}"
SKIP_MOVING_TAGS="${SKIP_MOVING_TAGS:-false}"
clean="${VERSION#v}"
cfg="images/$IMAGE/image.json"

tags=()
if [ "$VARIANT" != "default" ]; then
  tags+=("$VERSION-$VARIANT")
  [ "$clean" != "$VERSION" ] && tags+=("$clean-$VARIANT")
  tags+=("$clean-$VARIANT-$DATE")
  [ "$SKIP_MOVING_TAGS" != "true" ] && tags+=("$VARIANT")
fi
if [ "$IS_DEFAULT" = "true" ]; then
  tags+=("$VERSION")
  [ "$clean" != "$VERSION" ] && tags+=("$clean")
  tags+=("$clean-$DATE")
  [ "$SKIP_MOVING_TAGS" != "true" ] && tags+=("latest")
fi

# One digest file per arch; a missing file means that arch failed to build
shopt -s nullglob
digests=("$DIGESTS_DIR"/*)
if [ "${#digests[@]}" -ne "$(wc -w <<< "$ARCHS")" ]; then
  echo "::error::$IMAGE $VARIANT: expected digests for '$ARCHS', found ${#digests[@]}"
  exit 1
fi
sources=()
for d in "${digests[@]}"; do sources+=("ghcr.io/$OWNER/$IMAGE@sha256:$(basename "$d")"); done

annotations=(
  --annotation "index:org.opencontainers.image.title=$IMAGE"
  --annotation "index:org.opencontainers.image.description=$(jq -r '.description' "$cfg")"
  --annotation "index:org.opencontainers.image.url=$(jq -r '.homepage' "$cfg")"
  --annotation "index:org.opencontainers.image.licenses=$(jq -r '.license' "$cfg")"
  --annotation "index:org.opencontainers.image.version=$VERSION"
  --annotation "index:org.opencontainers.image.source=https://github.com/$GITHUB_REPOSITORY"
)

for registry in ghcr.io docker.io; do
  args=()
  for t in "${tags[@]}"; do args+=(-t "$registry/$OWNER/$IMAGE:$t"); done

  echo "Publish $registry/$OWNER/$IMAGE: ${tags[*]}"
  docker buildx imagetools create "${annotations[@]}" "${args[@]}" "${sources[@]}"
done

{
  echo "### $IMAGE $VARIANT $VERSION"
  for t in "${tags[@]}"; do echo "- \`$OWNER/$IMAGE:$t\`"; done
} >> "$GITHUB_STEP_SUMMARY"
