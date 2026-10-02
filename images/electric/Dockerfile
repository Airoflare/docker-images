# Electric sync service, built from source from the last release.
#
# ElectricSQL removed its public Docker images (electricsql/electric). This image
# builds the sync service from a preserved fork
# (github.com/Airoflare/electricsql-preserve) with the same steps as the upstream
# packages/sync-service/Dockerfile. Like the upstream image, it runs as root.
ARG ELECTRIC_VERSION

ARG ELIXIR_VERSION=1.20.2
ARG OTP_VERSION=29.0.2
ARG DEBIAN_VERSION=bookworm-20260623-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"
ARG MIX_TARGET=application

# Fetch only the two packages the build needs from the pinned release commit.
FROM alpine:3.24 AS source

# Commit of the @core/sync-service@1.8.1 release. Keep it in step with the
# version in scripts/helpers/electric.sh when moving to another release.
ARG ELECTRIC_COMMIT=0f404200402f918a4b1596bc5c8a53479a435349
ARG ELECTRIC_REPO=https://github.com/Airoflare/electricsql-preserve.git

RUN apk add --no-cache git
WORKDIR /src
RUN git init -q && git remote add origin "$ELECTRIC_REPO" && \
    git sparse-checkout set --no-cone /packages/sync-service /packages/electric-telemetry && \
    git fetch -q --depth 1 --filter=blob:none origin "$ELECTRIC_COMMIT" && \
    git checkout -q FETCH_HEAD

FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update -y && \
  apt-get install -y build-essential git curl && \
  apt-get clean && \
  rm -f /var/lib/apt/lists/*_*

RUN mix local.hex --force && mix local.rebar --force

ARG MIX_ENV=prod
ARG MIX_TARGET

WORKDIR /builder/electric

COPY --from=source /src/packages/electric-telemetry /builder/electric-telemetry

COPY --from=source /src/packages/sync-service/mix.* /builder/electric/
RUN mix deps.get
RUN MIX_OS_DEPS_COMPILE_PARTITION_COUNT=4 mix deps.compile

COPY --from=source /src/packages/sync-service/rel /builder/electric/rel
COPY --from=source /src/packages/sync-service/lib /builder/electric/lib/

COPY --from=source /src/packages/sync-service/package.json /builder/electric/
COPY --from=source /src/packages/sync-service/config/config.exs /builder/electric/config/

# The Electric app must be compiled after ELECTRIC_VERSION has been set
ARG ELECTRIC_VERSION
RUN mix compile
RUN mix sentry.package_source_code

COPY --from=source /src/packages/sync-service/config/runtime.exs /builder/electric/config/

RUN mix release

FROM ${RUNNER_IMAGE} AS final

RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates curl && \
  apt-get clean && \
  rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8 \
  MIX_ENV=prod \
  MIX_TARGET=application

WORKDIR /app

ARG MIX_TARGET
ARG RELEASE_NAME=electric
ARG ELECTRIC_VERSION

LABEL org.opencontainers.image.title="electric" \
  org.opencontainers.image.description="Electric sync service (Postgres sync engine), built from the last release in a preserved fork" \
  org.opencontainers.image.version="${ELECTRIC_VERSION}" \
  org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
  org.opencontainers.image.url="https://github.com/electric-sql/electric" \
  org.opencontainers.image.licenses="Apache-2.0"

COPY --from=builder "/builder/electric/_build/${MIX_TARGET}_prod/rel/${RELEASE_NAME}" ./

RUN mv /app/bin/${RELEASE_NAME} /app/bin/entrypoint

EXPOSE 3000
HEALTHCHECK --start-period=10s CMD curl --fail http://localhost:${ELECTRIC_PORT-3000}/v1/health || exit 1

ENTRYPOINT ["/app/bin/entrypoint"]
CMD ["start"]
